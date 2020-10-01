#============================================================= -*-perl-*-
#
# File::RsyncP package
#
# DESCRIPTION
#   File::RsyncP is a perl module that implements a subset of the
#   Rsync protocol, sufficient for implementing a client that can
#   talk to a native rsync server or rsyncd daemon.
#
# AUTHOR
#   Craig Barratt  <cbarratt@users.sourceforge.net>
#
# COPYRIGHT
#   File::RsyncP is Copyright (C) 2002-2015  Craig Barratt.
#
#   Rsync is Copyright (C) 1996-2001 by Andrew Tridgell, 1996 by Paul
#   Mackerras, 2001-2002 by Martin Pool, and 2003-2009 by Wayne Davison,
#   and others.
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#========================================================================
#
# Version 0.76, released 14 Sep 2020.
#
# See http://perlrsync.sourceforge.net.
#
#========================================================================

package File::RsyncP;

use strict;
use Socket;
use File::RsyncP::Digest;
use File::RsyncP::FileIO;
use File::RsyncP::FileList;
use Getopt::Long;
use Data::Dumper;
use Config;
use Encode qw/from_to/;
use Fcntl;

use vars qw($VERSION);
$VERSION = '0.76';

use constant S_IFMT       => 0170000;	# type of file
use constant S_IFDIR      => 0040000; 	# directory
use constant S_IFCHR      => 0020000; 	# character special
use constant S_IFBLK      => 0060000; 	# block special
use constant S_IFREG      => 0100000; 	# regular
use constant S_IFLNK      => 0120000; 	# symbolic link
use constant S_IFSOCK     => 0140000; 	# socket
use constant S_IFIFO      => 0010000; 	# fifo

sub new
{
    my($class, $options) = @_;

    $options ||= {};
    my $rs = bless {
        protocol_version => 28,
	logHandler       => \&logHandler,
	abort		 => 0,
	%$options,
    }, $class;

    #
    # In recent versions of rsync (eg: 2.6.8) --devices is no
    # longer identical to -D.  Now -D means --devices --specials.
    # File::RsyncP assumes --devices behaves the same as -D,
    # and doesn't currently handle --specials.
    #
    # To make sure we don't lie to the remote rsync, we must
    # send -D instead of --devices.  Therefore, we manually
    # replace --devices with -D in $rs->{rsyncArgs}.
    #
    for ( my $i = 0 ; $i < @{$rs->{rsyncArgs}} ; $i++ ) {
        $rs->{rsyncArgs}[$i] = "-D"
                    if ( $rs->{rsyncArgs}[$i] eq "--devices" );
    }

    #
    # process rsync options
    #
    local(@ARGV);
    $rs->{rsyncOpts} = {};
    @ARGV = @{$rs->{rsyncArgs}};

    my $p = new Getopt::Long::Parser(
		config => ["bundling", "pass_through"],
	    );

    #
    # First extract all the exclude related options for processing later
    #
    return if ( !$p->getoptions(
                "exclude=s",       sub { optExclude($rs, @_); },
                "exclude-from=s",  sub { optExclude($rs, @_); },
                "include=s",       sub { optExclude($rs, @_); },
                "include-from=s",  sub { optExclude($rs, @_); },
                "cvs-exclude|C",   sub { optExclude($rs, @_); },
	    ) );

    #
    # Since the exclude arguments are no longer needed (they are
    # passed via the socket, not the command-line args), update
    # $rs->{rsyncOpts}
    #
    @{$rs->{rsyncArgs}} = @ARGV;

    #
    # Now process the rest of the arguments we care about
    #
    return if ( !$p->getoptions($rs->{rsyncOpts},
		    "block-size=i",
		    "devices|D",
                    "from0|0",
		    "group|g",
		    "hard-links|H",
		    "ignore-times|I",
		    "links|l",
		    "numeric-ids",
		    "owner|o",
		    "perms|p",
		    "protocol=i",
		    "recursive|r",
		    "relative|R",
		    "timeout",
		    "verbose|v+",
	    ) );
    $rs->{blockSize}          = $rs->{rsyncOpts}{"block-size"};
    $rs->{timeout}          ||= $rs->{rsyncOpts}{timeout};
    $rs->{protocol_version}   = $rs->{rsyncOpts}{protocol}
		    if ( defined($rs->{rsyncOpts}{protocol}) );
    $rs->{fio_version} = 1;
    if ( !defined($rs->{fio}) ) {
	$rs->{fio} = File::RsyncP::FileIO->new({
			blockSize           => $rs->{blockSize},
			logLevel            => $rs->{logLevel},
                        protocol_version    => $rs->{protocol_version},
                        preserve_hard_links => $rs->{rsyncOpts}{"hard-links"},
			clientCharset       => $rs->{clientCharset},
		    });
	eval { $rs->{fio_version} = $rs->{fio}->version; };
    } else {
        #
        # Tell the existing FileIO module various parameters that
        # depend upon the parsed rsync args
        #
	eval { $rs->{fio_version} = $rs->{fio}->version; };
	$rs->{fio}->blockSize($rs->{blockSize});
	if ( $rs->{fio_version} >= 2 ) {
	    $rs->{fio}->protocol_version($rs->{protocol_version});
	    $rs->{fio}->preserve_hard_links($rs->{rsyncOpts}{"hard-links"});
	} else {
	    #
	    # old version of FileIO: only supports version 26
	    #
	    $rs->{protocol_version} = 26 if ( $rs->{protocol_version} > 26 );
	}
    }

    #
    # build signal list in case we do an abort
    #
    my $i = 0;
    foreach my $name ( split(' ', $Config{sig_name}) ) {
	$rs->{sigName2Num}{$name} = $i;
	$i++;
    }
    return $rs;
}

sub optExclude
{
    my($rs, $argName, $argValue) = @_;

    push(@{$rs->{excludeArgs}}, {name => $argName, value => $argValue});
}

#
# Strip the exclude and include arguments from the given argument list
#
sub excludeStrip
{
    my($rs, $args) = @_;
    local(@ARGV);
    my $p = new Getopt::Long::Parser(
		config => ["bundling", "pass_through"],
	    );

    @ARGV = @$args;

    #
    # Extract all the exclude related options
    #
    $p->getoptions(
            "exclude=s",       sub { },
            "exclude-from=s",  sub { },
            "include=s",       sub { },
            "include-from=s",  sub { },
            "cvs-exclude|C",   sub { },
        );

    return \@ARGV;
}

sub serverConnect
{
    my($rs, $host, $port) = @_;
    #local(*FH);

    $port ||= 873;
    my $proto = getprotobyname('tcp');
    my $iaddr = inet_aton($host)     || return "unknown host $host";
    my $paddr = sockaddr_in($port, $iaddr);

    alarm($rs->{timeout}) if ( $rs->{timeout} );
    socket(FH, PF_INET, SOCK_STREAM, $proto)
				    || return "inet socket: $!";
    connect(FH, $paddr)             || return "inet connect: $!";
    $rs->{fh} = *FH;
    $rs->writeData("\@RSYNCD: $rs->{protocol_version}\n", 1);
    my $line = $rs->getLine;
    alarm(0) if ( $rs->{timeout} );
    if ( $line !~ /\@RSYNCD:\s*(\d+)/ ) {
	return "unexpected response $line\n";
    }
    $rs->{remote_protocol} = $1;
    if ( $rs->{remote_protocol} < 20 || $rs->{remote_protocol} > 40 ) {
        return "Bad protocol version: $rs->{remote_protocol}\n";
    }
    $rs->log("Connected to $host:$port, remote version $rs->{remote_protocol}")
                        if ( $rs->{logLevel} >= 1 );
    $rs->{protocol_version} = $rs->{remote_protocol}
                        if ( $rs->{protocol_version} > $rs->{remote_protocol} );
    $rs->{fio}->protocol_version($rs->{protocol_version})
			if ( $rs->{fio_version} >= 2 );
    $rs->log("Negotiated protocol version $rs->{protocol_version}")
                        if ( $rs->{logLevel} >= 1 );
    return;
}

sub serverList
{
    my($rs) = @_;
    my(@service);

    return "not connected" if ( !defined($rs->{fh}) );
    $rs->writeData("#list\n", 1);
    while ( 1 ) {
        my $line = $rs->getLine;
        $rs->log("Got `$line'") if ( $rs->{logLevel} >= 2 );
        last if ( $line eq "\@RSYNCD: EXIT" );
        push(@service, $line);
    }
    return @service;
}

sub serverService
{
    my($rs, $service, $user, $passwd, $authRequired) = @_;
    my($line);

    return "not connected" if ( !defined($rs->{fh}) );
    $rs->writeData("$service\n", 1);
    $line = $rs->getLine;
    return $1 if ( $line =~ /\@ERROR: (.*)/ );
    if ( $line =~ /\@RSYNCD: AUTHREQD (.{22})/ ) {
	my $challenge = $1;
	my $md4 = File::RsyncP::Digest->new($rs->{protocol_version});
	$md4->add(pack("V", 0));
	$md4->add($passwd);
	$md4->add($challenge);
	my $response = $md4->digest;
	$rs->log("Got response: " . unpack("H*", $response))
		    if ( $rs->{logLevel} >= 2 );
	my $response1 = $rs->encode_base64($response);
	$rs->log("in mime: " . $response1) if ( $rs->{logLevel} >= 5 );
	$rs->writeData("$user $response1\n", 1);
        $rs->log("Auth: got challenge: $challenge, reply: $user $response1")
		    if ( $rs->{logLevel} >= 2 );
        $line = $rs->getLine;
    } elsif ( $authRequired ) {
        return "auth required, but service $service is open/insecure";
    }
    return $1 if ( $line =~ /\@ERROR: (.*)/ );
    if ( $line ne "\@RSYNCD: OK" ) {
	return "unexpected response: '$line'";
    }
    $rs->log("Connected to module $service") if ( $rs->{logLevel} >= 1 );
    return;
}

sub serverStart
{
    my($rs, $remoteSend, $remoteDir) = @_;

    my @args = @{$rs->{rsyncArgs}};
    unshift(@args, "--sender") if ( $remoteSend );
    unshift(@args, "--server");
    push(@args, ".", $remoteDir);
    $rs->{remoteSend} = $remoteSend;
    $rs->writeData(join("\n", @args) . "\n\n", 1);
    $rs->log("Sending args: " . join(" ", @args)) if ( $rs->{logLevel} >= 1 );
}

sub encode_base64
{
    my($rs, $str) = @_;

    my $s2 = pack('u', $str);
    $s2 =~ tr|` -_|AA-Za-z0-9+/|;
    return substr($s2, 1, int(1.0 - 1e-10 + length($str) * 8 / 6));
}

sub remoteStart
{
    my($rs, $remoteSend, $remoteDir) = @_;
    local(*RSYNC);
    my($pid, $cmd);

    socketpair(RSYNC, FH, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
				      or die "socketpair: $!";
    socketpair(RSYNC_STDERR, FH_STDERR, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
				      or die "socketpair: $!";
    $rs->{remoteSend} = $remoteSend;
    $rs->{remoteDir}  = $remoteDir;

    $rs->{rsyncCmd} = [split(" ", $rs->{rsyncCmd})]
		    if ( ref($rs->{rsyncCmd}) ne 'ARRAY'
		      && ref($rs->{rsyncCmd}) ne 'CODE' );
    if ( $rs->{rsyncCmdType} eq "full" || ref($rs->{rsyncCmd}) ne 'ARRAY' ) {
        $cmd = $rs->{rsyncCmd};
    } else {
        $cmd = $rs->{rsyncArgs};
        unshift(@$cmd, "--sender") if ( $remoteSend );
        unshift(@$cmd, "--server");
        if ( $rs->{rsyncCmdType} eq "shell" ) {
            #
            # Do shell escaping of rsync arguments
            #
            for ( my $i = 0 ; $i < @$cmd ; $i++ ) {
                $cmd->[$i] = $rs->shellEscape($cmd->[$i]);
            }
            $remoteDir = $rs->shellEscape($remoteDir);
        }
        $cmd = [@{$rs->{rsyncCmd}}, @$cmd];
	if ( $remoteSend ) {
	    push(@$cmd, ".", $remoteDir);
	} else {
	    push(@$cmd, ".");
	}
    }
    $rs->log("Running: " . join(" ", @$cmd))
		    if ( ref($cmd) eq 'ARRAY' && $rs->{logLevel} >= 1 );
    if ( !($pid = fork()) ) {
	#
	# The child execs rsync.
	#
	close(FH);
	close(FH_STDERR);
	close(STDIN);
	close(STDOUT);
        close(STDERR);
	open(STDIN, "<&RSYNC");
	open(STDOUT, ">&RSYNC");
        open(STDERR, ">&RSYNC_STDERR");
	if ( ref($cmd) eq 'CODE' ) {
	    &$cmd();
	} else {
	    exec(@$cmd);
	}
	# not reached
	# $rs->log("Failed to exec rsync command $cmd[0]");
	# exit(0);
    }
    close(RSYNC);
    close(RSYNC_STDERR);
    $rs->{fh} = *FH;
    $rs->{fh_stderr} = *FH_STDERR;
    $rs->{rsyncPID} = $pid;
    $rs->{pidHandler}->($rs->{rsyncPID}, $rs->{childPID})
			if ( defined($rs->{pidHandler}) );
    #
    # Write our version and get the remote version
    #
    $rs->writeData(pack("V", $rs->{protocol_version}), 1);
    $rs->log("Rsync command pid is $pid") if ( $rs->{logLevel} >= 3 );
    $rs->log("Fetching remote protocol") if ( $rs->{logLevel} >= 5 );
    return -1 if ( $rs->getData(4) < 0 );
    my $data = $rs->{readData};
    my $version = unpack("V", $rs->{readData});
    $rs->{readData} = substr($rs->{readData}, 4);
    $rs->{remote_protocol} = $version;
    $rs->log("Got remote protocol $version") if ( $rs->{logLevel} >= 1 );
    $rs->{protocol_version} = $rs->{remote_protocol}
                    if ( $rs->{protocol_version} > $rs->{remote_protocol} );
    $rs->{fio}->protocol_version($rs->{protocol_version})
	    if ( $rs->{fio_version} >= 2 );
    if ( $version < 20 || $version > 40 ) {
        $rs->log("Fatal error (bad version): $data");
        return -1;
    }
    $rs->log("Negotiated protocol version $rs->{protocol_version}")
                    if ( $rs->{logLevel} >= 1 );
    return;
}

sub serverClose
{
    my($rs) = @_;

    return if ( !defined($rs->{fh}) );
    close($rs->{fh});
    $rs->{fh} = undef;
    close($rs->{fh_stderr}) if defined($rs->{fh_stderr});
    $rs->{fh_stderr} = undef;
}

sub go
{
    my($rs, $localDir) = @_;

    my $remoteDir = $rs->{remoteDir};
    return $rs->{fatalErrorMsg} if ( $rs->getData(4) < 0 );
    $rs->{checksumSeed} = unpack("V", $rs->{readData});
    $rs->{readData} = substr($rs->{readData}, 4);
    $rs->{fio}->checksumSeed($rs->{checksumSeed});
    $rs->{fio}->dirs($localDir, $remoteDir);
    $rs->log(sprintf("Got checksumSeed 0x%x", $rs->{checksumSeed}))
		    if ( $rs->{logLevel} >= 2 );

    if ( $rs->{remoteSend} ) {
        #
        # Get the file list from the remote sender
        #
        if ( $rs->fileListReceive() < 0 ) {
	    $rs->log("fileListReceive() failed");
	    return "fileListReceive failed";
	}

        #
        # Sort and match inode data if hardlinks are enabled
        #
        if ( $rs->{rsyncOpts}{"hard-links"} ) {
            $rs->{fileList}->init_hard_links();
            ##my $cnt = $rs->{fileList}->count;
            ##for ( my $n = 0 ; $n < $cnt ; $n++ ) {
            ##  my $f = $rs->{fileList}->get($n);
            ##  print Dumper($f);
            ##}
        }

	if ( $rs->{logLevel} >= 2 ) {
	    my $cnt = $rs->{fileList}->count;
	    $rs->log("Got file list: $cnt entries");
	}

        #
        # At this point the uid/gid list would be received,
        # but with numeric-ids nothing is sent.  We currently
        # only support the numeric-ids case.
        #

        #
        # Read and skip a word: this is the io_error flag.
        #
        return "can't read io_error flag" if ( $rs->getChunk(4) < 0 );
	$rs->{chunkData} = substr($rs->{chunkData}, 4);

	#
	# If this is a partial, then check which files we are
	# going to skip
	#
	$rs->partialFileListPopulate() if ( $rs->{doPartial} );

        #
        # Dup the $rs->{fh} socket file handle into two pieces: read-only
        # and write-only.  The child gets the read-only handle and
        # we keep the write-only one.  We make the write-only handle
        # non-blocking.
        # 
        my $pid;
        local(*RH, *WH, *FHWr, *FHRd);

	socketpair(RH, WH, AF_UNIX, SOCK_STREAM, PF_UNSPEC);
	shutdown(RH, 1);
	shutdown(WH, 0);

        open(FHWr, ">&$rs->{fh}");
        open(FHRd, "<&$rs->{fh}");
        close($rs->{fh});

        if ( !($pid = fork()) ) {
            #
            # The child receives the file deltas in two passes.
            # If a file needs to be repeated in phase 2 we send
            # the file into the the parent via the pipe.
	    #
	    # First the log handler for both us and fio has to forward
	    # to the parent, so redefine them.
	    #
	    $rs->{logHandler} = sub {
			my($str) = @_;    
                        $str =~ s/\n/\\n/g;
                        $str =~ s/\r/\\r/g;
			print WH "log $str\n";
		    };
	    $rs->{fio}->logHandlerSet(sub {
			my($str) = @_;    
                        $str =~ s/\n/\\n/g;
                        $str =~ s/\r/\\r/g;
			print WH "log $str\n";
		    });
            close(RH);
            close(FHWr);
            $rs->{fh} = *FHRd;
	    setsockopt($rs->{fh}, SOL_SOCKET, SO_RCVBUF, 8 * 65536);
	    setsockopt(WH, SOL_SOCKET, SO_SNDBUF, 8 * 65536);
            my $oldFH = select(WH); $| = 1; select($oldFH);
            $rs->fileDeltaGet(*WH, 0);
            $rs->log("Child is sending done")
			    if ( $rs->{logLevel} >= 5 );
            print(WH "done\n");
            $rs->fileDeltaGet(*WH, 1) if ( !$rs->{abort} );
            #
            # Get stats
            #
            $rs->statsGet(*WH);
            #
            # Final signoff
            #
            $rs->writeData(pack("V", 0xffffffff), 1);
	    $rs->{fio}->finish(1);
            $rs->log("Child is aborting") if ( $rs->{abort} );
            print(WH "exit\n");
            exit(0);
        }
        close(WH);
        close(FHRd);
        $rs->{fh} = *FHWr;
        close($rs->{fh_stderr});
        $rs->{fh_stderr} = undef;

	#
	# Make our write handle non-blocking
	#
	my $flags = '';
	if ( fcntl($rs->{fh}, F_GETFL, $flags) ) {
	    $flags |= O_NONBLOCK;
	    if ( !fcntl($rs->{fh}, F_SETFL, $flags) ) {
		$rs->log("Parent fcntl(F_SETFL) failed; non-block set failed");
	    }
	} else {
	    $rs->log("Parent fcntl(F_GETFL) failed; non-block failed");
	}

	$rs->{childFh}  = *RH;
	$rs->{childPID} = $pid;
	$rs->log("Child PID is $pid") if ( $rs->{logLevel} >= 2 );
	$rs->{pidHandler}->($rs->{rsyncPID}, $rs->{childPID})
			    if ( defined($rs->{pidHandler}) );
	setsockopt($rs->{fh}, SOL_SOCKET, SO_SNDBUF, 8 * 65536);
	setsockopt($rs->{childFh}, SOL_SOCKET, SO_RCVBUF, 8 * 65536);
        #
        # The parent generates the file checksums and waits for
        # the child to finish.  The child tells us if any files
        # need to be repeated for phase 2.
        #
        # Phase 1: csum length is 2 (or >= 2 for protocol_version >= 27)
        #
        $rs->fileCsumSend(0);

        #
        # Phase 2: csum length is 16
        #
        $rs->fileCsumSend(1);

	if ( $rs->{abort} ) {
	    #
	    # If we are aborting, give the child a few seconds
	    # to finish up.
	    #
	    for ( my $i = 0 ; $i < 10 ; $i++ ) {
		last if ( $rs->{childDone} >= 3 || $rs->pollChild(1) < 0 );
	    }
	    $rs->{fatalErrorMsg} = $rs->{abortReason}
			    if ( !defined($rs->{fatalErrorMsg}) );
	}
	
	#
	# Done
	#
	$rs->{fio}->finish(0);
        close(RH);
        return $rs->{fatalErrorMsg} if ( defined($rs->{fatalErrorMsg}) );
        return;
    } else {
        #syswrite($rs->{fh}, pack("V", time));
        #
        # Send the file list to the remote server
        #
        $rs->fileListSend();
        return $rs->{fatalErrorMsg} if ( $rs->{fatalError} );

        #
        # Phase 1: csum length is 2
        #
        $rs->fileCsumReceive(0);
        return $rs->{fatalErrorMsg} if ( $rs->{fatalError} );

        #
        # Phase 2: csum length is 3
        #
        $rs->fileCsumReceive(1);
        return $rs->{fatalErrorMsg} if ( $rs->{fatalError} );

	#
	# Get final int handshake, and wait for EOF
	#
	$rs->getData(4);
	return -1 if ( $rs->{abort} );
        sysread($rs->{fh}, my $data, 1);

        return;
    }
}

#
# When a partial rsync is done (meaning selective per-file ignore-attr)
# we pass through the file list and remember which files we should
# skip.  This allows the child to callback the user on each skipped
# file.
#
sub partialFileListPopulate
{
    my($rs) = @_;
    my $cnt = $rs->{fileList}->count;
    for ( my $n = 0 ; $n < $cnt ; $n++ ) {
	my $f = $rs->{fileList}->get($n);
	next if ( !defined($f) );
        from_to($f->{name}, $rs->{clientCharset}, "utf8")
                                if ( $rs->{clientCharset} ne "" );
	my $attr = $rs->{fio}->attribGet($f);
	my $thisIgnoreAttr = $rs->{fio}->ignoreAttrOnFile($f);

	#
	# check if we should skip this file: same type, size, mtime etc
	#
	if ( !$thisIgnoreAttr
	      && $f->{size}  == $attr->{size}
	      && $f->{mtime} == $attr->{mtime}
	      && (!$rs->{rsyncOpts}{perms} || $f->{mode} == $attr->{mode})
	      && (!$rs->{rsyncOpts}{group} || $f->{gid} == $attr->{gid})
	      && (!$rs->{rsyncOpts}{owner} || $f->{uid} == $attr->{uid})
	      && (!$rs->{rsyncOpts}{"hard-links"}
                        || $f->{hlink_self} == $attr->{hlink_self}) ) {
	    $rs->{fileList}->flagSet($n, 1);
	}
    }
}

sub fileListReceive
{
    my($rs) = @_;
    my($flags, $l1, $l2, $namel1, $name, $length, $mode, $mtime,
	$uid, $gid, $rdev);
    my($data, $flData);

    $rs->{fileList} = File::RsyncP::FileList->new({
        preserve_uid        => $rs->{rsyncOpts}{owner},
        preserve_gid        => $rs->{rsyncOpts}{group},
        preserve_links      => $rs->{rsyncOpts}{links},
        preserve_devices    => $rs->{rsyncOpts}{devices},
        preserve_hard_links => $rs->{rsyncOpts}{"hard-links"},
        always_checksum     => $rs->{rsyncOpts}{checksum},
        protocol_version    => $rs->{protocol_version},
    });

    #
    # Process the exclude/include arguments and send the
    # exclude/include file list
    #
    foreach my $arg ( @{$rs->{excludeArgs}} ) {
        if ( $arg->{name} eq "exclude" ) {
            $rs->{fileList}->exclude_add($arg->{value}, 0);
        } elsif ( $arg->{name} eq "include" ) {
            $rs->{fileList}->exclude_add($arg->{value}, 2);
        } elsif ( $arg->{name} eq "exclude-from" ) {
            $rs->{fileList}->exclude_add_file($arg->{value}, 1);
        } elsif ( $arg->{name} eq "include-from" ) {
            $rs->{fileList}->exclude_add_file($arg->{value}, 3);
        } elsif ( $arg->{name} eq "cvs-exclude" ) {
            $rs->{fileList}->exclude_cvs_add();
        } else {
            $rs->log("Error: Don't recognize exclude argument $arg->{name}"
                   . " ($arg->{value})");
        }
    }
    $rs->{fileList}->exclude_list_send();
    $rs->writeData($rs->{fileList}->encodeData(), 1);
    if ( $rs->{logLevel} >= 1 ) {
        foreach my $exc ( @{$rs->{fileList}->exclude_list_get()} ) {
            from_to($exc->{pattern}, $rs->{clientCharset}, "utf8")
                                    if ( $rs->{clientCharset} ne "" );
            if ( $exc->{flags} & (1 << 4) ) {
                $rs->log("Sent include: $exc->{pattern}");
            } else {
                $rs->log("Sent exclude: $exc->{pattern}");
            }
        }
    }

    #
    # Now receive the file list
    #
    my $curr = 0;
    while ( !$rs->{fileList}->decodeDone ) {
        return -1 if ( $rs->{chunkData} eq "" && $rs->getChunk(1) < 0 );
        my $cnt = $rs->{fileList}->decode($rs->{chunkData});
	return -1 if ( $rs->{fileList}->fatalError );
	if ( $rs->{logLevel} >= 4 ) {
	    my $end = $rs->{fileList}->count;
	    while ( $curr < $end ) {
		my $f = $rs->{fileList}->get($curr);
		next if ( !defined($f) );
                from_to($f->{name}, $rs->{clientCharset}, "utf8")
                                        if ( $rs->{clientCharset} ne "" );
		$rs->log("Got file ($curr of $end): $f->{name}");
		$curr++;
	    }
	}
        if ( $cnt > 0 ) {
            $rs->{chunkData} = substr($rs->{chunkData}, $cnt);
	    return -1 if ( !$rs->{fileList}->decodeDone
			&& $rs->getChunk(length($rs->{chunkData}) + 1) < 0 );
        }
    }

    #
    # Sort and clean the file list
    #
    $rs->{fileList}->clean;
}

#
# Called by the child process to create directories, special files,
# and optionally to set attributes on normal files.
#
sub fileSpecialCreate
{
    my($rs, $start, $end) = @_;

    $end = $rs->{fileList}->count if ( !defined($end) );
    for ( my $n = $start ; $n < $end ; $n++ ) {
	my $f = $rs->{fileList}->get($n);
	next if ( !defined($f) );
        from_to($f->{name}, $rs->{clientCharset}, "utf8")
                                if ( $rs->{clientCharset} ne "" );
	my $attr = $rs->{fio}->attribGet($f);

	if ( $rs->{doPartial} && $rs->{fileList}->flagGet($n) ) {
	    $rs->{fio}->attrSkippedFile($f, $attr);
	    next;
	}

	$rs->{fio}->attribSet($f, 1);

	if ( ($f->{mode} & S_IFMT) != S_IFREG ) {
	    #
	    # A special file
	    #
	    if ( ($f->{mode} & S_IFMT) == S_IFDIR ) {
		if ( $rs->{fio}->makePath($f) ) {
		    # error
                    $rs->log("Error: makePath($f->{name}) failed");
		}
	    } else {
		if ( $rs->{fio}->makeSpecial($f) ) {
		    # error
                    $rs->log("Error: makeSpecial($f->{name}) failed");
		}
	    }
	} elsif ( defined($f->{hlink}) && !$f->{hlink_self} ) {
            if ( $rs->{fio}->makeHardLink($f, 0) ) {
                $rs->log("Error: makeHardlink($f->{name} -> $f->{hlink}) failed");
            }
        }
    }
}

sub fileCsumSend
{
    my($rs, $phase) = @_;
    my $csumLen = $phase == 0 ? 2 : 16;
    my $ignoreAttr = $rs->{rsyncOpts}{"ignore-times"};

    $rs->{phase} = $phase;
    my $cnt = $rs->{fileList}->count;
    $rs->{doList} = [0..($cnt-1)] if ( $phase == 0 );
    $rs->{redoList} = [];
    if ( $rs->{logLevel} >= 2 ) {
	my $cnt = @{$rs->{doList}};
	$rs->log("Sending csums, cnt = $cnt, phase = $phase");
    }
    while ( @{$rs->{doList}} || $phase == 1 && $rs->{childDone} < 3 ) {
	if ( @{$rs->{doList}} ) {
	    my $n = shift(@{$rs->{doList}});
            my $f = $rs->{fileList}->get($n);
	    next if ( !defined($f) );
            from_to($f->{name}, $rs->{clientCharset}, "utf8")
                                    if ( $rs->{clientCharset} ne "" );

	    if ( $rs->{doPartial} && $rs->{fileList}->flagGet($n) ) {
		$rs->log("Skipping $f->{name} (same attr on partial)")
			    if ( $rs->{logLevel} >= 3
			       && ($f->{mode} & S_IFMT) == S_IFREG );
		next;
	    }

	    #
	    # check if we should skip this file: same type, size, mtime etc
	    #
            my $attr = $rs->{fio}->attribGet($f);

	    if ( !$ignoreAttr
                  && $phase == 0
		  && $f->{size}  == $attr->{size}
		  && $f->{mtime} == $attr->{mtime}
		  && (!$rs->{rsyncOpts}{perms} || $f->{mode} == $attr->{mode})
		  && (!$rs->{rsyncOpts}{group} || $f->{gid} == $attr->{gid})
		  && (!$rs->{rsyncOpts}{owner} || $f->{uid} == $attr->{uid})
                  && (!$rs->{rsyncOpts}{"hard-links"}
                            || $f->{hlink_self} == $attr->{hlink_self}) ) {
		$rs->log("Skipping $f->{name} (same attr)")
			    if ( $rs->{logLevel} >= 3
			       && ($f->{mode} & S_IFMT) == S_IFREG );
		next;
	    }

            my $blkSize;
            if ( ($f->{mode} & S_IFMT) != S_IFREG ) {
                #
                # Remote file is special: no checksum needed.
                #
                next;
            } elsif ( $rs->{rsyncOpts}{"hard-links"}
                            && defined($f->{hlink})
                            && !$f->{hlink_self} ) {
                #
                # Skip any hardlinks; the child will create them later
                #
                next;
            } elsif ( !defined($attr->{mode})
			|| ($attr->{mode} & S_IFMT) != S_IFREG ) {
                #
                # Local file isn't a regular file but remote is.
		# So delete the local file and send an empty
		# checksum.
                #
		$rs->{fio}->unlink($f->{name}) if ( defined($attr->{mode}) );
		$rs->log("Sending empty csums for $f->{name}")
				    if ( $rs->{logLevel} >= 5 );
                $rs->write_sum_head($n, 0, $rs->{blockSize}, $csumLen, 0);
            } elsif ( ($blkSize = $rs->{fio}->csumStart($f, 0, $rs->{blockSize},
                                                        $phase)) < 0 ) {
		#
		# Can't open the file, so send an empty checksum
		#
		$rs->log("Sending empty csums for $f->{name}")
				    if ( $rs->{logLevel} >= 5 );
                $rs->write_sum_head($n, 0, $rs->{blockSize}, $csumLen, 0);
	    } else {
		#
		# The local file is a regular file, so generate and
		# send the checksums.
                #

                #
                # Compute adaptive block size, from $rs->{blockSize}
                # to 16384 based on file size.
		#
                if ( $blkSize <= 0 ) {
                    $blkSize = int($attr->{size} / 10000);
                    $blkSize = $rs->{blockSize}
                                    if ( $blkSize < $rs->{blockSize} );
                    $blkSize = 16384 if ( $blkSize > 16384 );
                }
		my $blkCnt = int(($attr->{size} + $blkSize - 1)
						/ $blkSize);
		$rs->log("Sending csums for $f->{name} (size=$attr->{size})")
				if ( $rs->{logLevel} >= 5 );
                $rs->write_sum_head($n, $blkCnt, $blkSize, $csumLen,
                            $blkCnt > 0
                                ? $attr->{size} - ($blkCnt - 1) * $blkSize
                                : $attr->{size});
		my $nWrite = ($csumLen + 4) * $blkCnt;
		while ( $blkCnt > 0 && $nWrite > 0 ) {
		    my $thisCnt = $blkCnt > 256 ? 256 : $blkCnt;
		    my $csum = $rs->{fio}->csumGet($thisCnt, $csumLen,
						   $blkSize);
		    $rs->writeData($csum);
		    $nWrite -= length($csum);
		    $blkCnt -= $thisCnt;
		    return if ( $rs->{abort} );
		}
		#
		# In case the reported file size was wrong, we need to
		# send enough checksum data.  It's not clear that sending
		# zeros is right, but this shouldn't happen in any case.
		#
                if ( $nWrite > 0 && !$rs->{abort} ) {
		    $rs->writeData(pack("c", 0) x $nWrite);
                }
		$rs->{fio}->csumEnd;
	    }
	}
	if ( !@{$rs->{doList}} && $phase == 1 && $rs->{childDone} == 1 ) {
	    #
	    # end of phase 1
	    #
	    $rs->writeData(pack("V", 0xffffffff), 1);
	    $rs->{childDone} = 2;
	}
	#
	# Now poll the pipe from the child to see if there are any
	# files we need to redo on the second phase
	#
	# If there are no more files but we haven't seen "exit"
	# from the child then block forever.
	#
        return if ( $rs->{abort} );
	$rs->pollChild(($phase == 1 && !@{$rs->{doList}}) ? undef : 0);
    }
    if ( $phase == 0 ) {
	#
	# end of phase 0
	#
	$rs->writeData(pack("V", 0xffffffff), 1);
	$rs->{doList} = $rs->{redoList};
    }
}

#
# See if there are any messges from the local child over the pipe.
# These could be logging messages or requests to repeat files.
#
sub pollChild
{
    my($rs, $timeout) = @_;
    my($FDread);

    return -1 if ( !defined($rs->{childFh}) );
    $rs->log("pollChild($timeout)") if ( $rs->{logLevel} >= 12 );

    vec($FDread, fileno($rs->{childFh}), 1) = 1;
    my $ein = $FDread;
    #$rs->log("pollChild: select(timeout=$timeout)");
    select(my $rout = $FDread, undef, $ein, $timeout);
    return if ( !vec($rout, fileno($rs->{childFh}), 1) );
    #$rs->log("pollChild: reading from child");
    my $nbytes = sysread($rs->{childFh}, my $mesg, 65536);
    #$rs->log("pollChild: done reading from child");
    $rs->{childMesg} .= $mesg if ( $nbytes > 0 );
    if ( $nbytes <= 0 ) {
        close($rs->{childFh});
        delete($rs->{childFh});
	$rs->log("Parent read EOF from child: fatal error!")
		if ( $rs->{logLevel} >= 1 );
        $rs->{abort}         = 1;
        $rs->{fatalError}    = 1;
        $rs->{fatalErrorMsg} = "Child exited prematurely";
	return -1;
    }
    #
    # Process any complete lines of output from the child.
    #
    # Because some regexps are very slow in 5.8.0, this old code:
    #
    #    while ( $rs->{childMesg} =~ /(.*?)[\n\r]+(.*)/s ) {
    #        $mesg = $1;
    #        $rs->{childMesg} = $2;
    #
    # was replaced with the split() below.
    #
    while ( $rs->{childMesg} =~ /[\n\r]/ ) {
	($mesg, $rs->{childMesg}) = split(/[\n\r]+/, $rs->{childMesg}, 2);
	$rs->log("Parent read: $mesg")
		    if ( $rs->{logLevel} >= 20 );
	if ( $mesg =~ /^done$/ ) {
	    $rs->log("Got done from child")
			if ( $rs->{logLevel} >= 4 );
	    $rs->{childDone} = 1;
	} elsif ( $mesg =~ /^stats (\d+) (\d+) (\d+) (\d+) (.*)/ ) {
	    $rs->{stats}{totalRead}    = $1;
	    $rs->{stats}{totalWritten} = $2;
	    $rs->{stats}{totalSize}    = $3;
	    $rs->{stats}{remoteErrCnt} += $4;
	    my %childStats = eval($5);
	    $rs->log("Got stats: $1 $2 $3 $4 $5")
			if ( $rs->{logLevel} >= 4 );
	    $rs->{stats}{childStats}   = \%childStats;
	    $rs->{stats}{parentStats}  = $rs->{fio}->statsGet;
	} elsif ( $mesg =~ /^exit/ ) {
	    $rs->log("Got exit from child") if ( $rs->{logLevel} >= 4 );
	    $rs->{childDone} = 3;
	} elsif ( $mesg =~ /^redo (\d+)/ ) {
	    if ( $rs->{phase} == 1 ) {
		push(@{$rs->{doList}}, $1);
	    } else {
		push(@{$rs->{redoList}}, $1);
	    }
	    $rs->log("Got redo $1") if ( $rs->{logLevel} >= 4 );
	} elsif ( $mesg =~ /^log (.*)/ ) {
	    $rs->log($1);
	} else {
	    $rs->log("Don't understand '$mesg' from child");
	}
    }
}

sub fileCsumReceive
{
    my($rs, $phase) = @_;
    my($fileNum, $blkCnt, $blkSize, $remainder);
    my $csumLen = $phase == 0 ? 2 : 16;
    #
    # delete list -> disabled by argv
    #
    #  $rs->writeData(pack("V", 1));
    #
    while ( 1 ) {
	return -1 if ( $rs->getChunk(4) < 0 );
	$fileNum = unpack("V", $rs->{chunkData});
	$rs->{chunkData} = substr($rs->{chunkData}, 4);
	if ( $fileNum == 0xffffffff ) {
	    $rs->log("Finished csumReceive")
		    if ( $rs->{logLevel} >= 2 );
	    last;
	}
        my $f = $rs->{fileList}->get($fileNum);
	next if ( !defined($f) );
        from_to($f->{name}, $rs->{clientCharset}, "utf8")
                                if ( $rs->{clientCharset} ne "" );
        if ( $rs->{protocol_version} >= 27 ) {
            return -1 if ( $rs->getChunk(16) < 0 );
            my $thisCsumLen;
            ($blkCnt, $blkSize, $thisCsumLen, $remainder)
                            = unpack("V4", $rs->{chunkData});
            $rs->{chunkData} = substr($rs->{chunkData}, 16);
        } else {
            return -1 if ( $rs->getChunk(12) < 0 );
            ($blkCnt, $blkSize, $remainder) = unpack("V3", $rs->{chunkData});
            $rs->{chunkData} = substr($rs->{chunkData}, 12);
        }
	$rs->log("Got #$fileNum ($f->{name}), blkCnt=$blkCnt,"
                 . " blkSize=$blkSize, rem=$remainder")
			if ( $rs->{logLevel} >= 5 );
        #
        # For now we just check if the file is identical or not.
        # We don't do clever differential restores; we effectively
        # do --whole-file for sending to the remote machine.
	#
	# All this code needs to be replaced with proper file delta
	# generation...
        # 
        next if ( ($f->{mode} & S_IFMT) != S_IFREG );
        $rs->{fio}->csumStart($f, 1, $blkSize, $phase);
        my $attr = $rs->{fio}->attribGet($f);
        my $fileSame = $attr->{size} == ($blkCnt > 0
				        ? ($blkCnt - 1) * $blkSize + $remainder
				        : 0);
	my $cnt = $blkCnt;
        while ( $cnt > 0 ) {
            my $thisCnt = $cnt > 256 ? 256 : $cnt;
            my $len = $thisCnt * ($csumLen + 4);
            my $csum = $rs->{fio}->csumGet($thisCnt, $csumLen, $blkSize)
					if ( $fileSame );
            $rs->getChunk($len);
            my $csumRem = unpack("a$len", $rs->{chunkData});
	    $rs->{chunkData} = substr($rs->{chunkData}, $len);
            $fileSame = 0 if ( $csum ne $csumRem );
            $rs->log(sprintf("   got same=%d, local=%s, remote=%s",
                    $fileSame, unpack("H*", $csum), unpack("H*", $csumRem)))
                                if ( $rs->{logLevel} >= 8 );
            $cnt -= $thisCnt;
        }

        my $md4 = $rs->{fio}->csumEnd;
        #
        # Send the file number, numBlocks, blkSize and remainder
        # (based on the old file size)
        #
        ##$blkCnt = int(($attr->{size} + $blkSize - 1) / $blkSize);
        ##$remainder = $attr->{size} - ($blkCnt - 1) * $blkSize;
        $rs->write_sum_head($fileNum, $blkCnt, $blkSize, $csumLen, $remainder);

        if ( $fileSame ) {
	    $rs->log("$f->{name}: unchanged") if ( $rs->{logLevel} >= 3 );
	    #
	    # The file is the same, so just send a bunch of block numbers
	    #
	    for ( my $blk = 1 ; $blk <= $blkCnt ; $blk++ ) {
		$rs->writeData(pack("V", -$blk));
	    }
	} else { 
	    #
	    # File doesn't match: send the file
	    #
	    $rs->{fio}->readStart($f);
	    while ( 1 ) {
		my $dataR = $rs->{fio}->read(4 * 65536);
		last if ( !defined($dataR) || length($$dataR) == 0 );
		$rs->writeData(pack("V a*", length($$dataR), $$dataR));
	    }
	    $rs->{fio}->readEnd($f);
	}

        #
        # Send a final 0 and the MD4 file digest
        #
        $rs->writeData(pack("V a16", 0, $md4));
    }

    #
    # Indicate end of this phase
    #
    $rs->writeData(pack("V", 0xffffffff), 1);
}

sub fileDeltaGet
{
    my($rs, $fh, $phase) = @_;
    my($fileNum, $blkCnt, $blkSize, $remainder, $len, $d, $token);
    my $fileStart = 0;

    while ( 1 ) {
	return -1 if ( $rs->getChunk(4) < 0 );
	$fileNum = unpack("V", $rs->{chunkData});
	$rs->{chunkData} = substr($rs->{chunkData}, 4);
	last if ( $fileNum == 0xffffffff );

	#
	# Make any intermediate dirs or special files
	#
	$rs->fileSpecialCreate($fileStart, $fileNum) if ( $phase == 0 );
	$fileStart = $fileNum + 1;

        my $f = $rs->{fileList}->get($fileNum);
	next if ( !defined($f) );
        from_to($f->{name}, $rs->{clientCharset}, "utf8")
                                if ( $rs->{clientCharset} ne "" );
        if ( $rs->{protocol_version} >= 27 ) {
            return -1 if ( $rs->getChunk(16) < 0 );
            my $thisCsumLen;
            ($blkCnt, $blkSize, $thisCsumLen, $remainder)
                            = unpack("V4", $rs->{chunkData});
            $rs->{chunkData} = substr($rs->{chunkData}, 16);
        } else {
            return -1 if ( $rs->getChunk(12) < 0 );
            ($blkCnt, $blkSize, $remainder) = unpack("V3", $rs->{chunkData});
            $rs->{chunkData} = substr($rs->{chunkData}, 12);
        }
	$rs->log("Starting file $fileNum ($f->{name}),"
	    . " blkCnt=$blkCnt, blkSize=$blkSize, remainder=$remainder")
		    if ( $rs->{logLevel} >= 5 );
        $rs->{fio}->fileDeltaRxStart($f, $blkCnt, $blkSize, $remainder);
        
        while ( 1 ) {
	    return -1 if ( $rs->getChunk(4) < 0 );
            $len = unpack("V", $rs->{chunkData});
	    $rs->{chunkData} = substr($rs->{chunkData}, 4);
            if ( $len == 0 ) {
		return -1 if ( $rs->getChunk(16) < 0 );
                my $md4digest = unpack("a16", $rs->{chunkData});
		$rs->{chunkData} = substr($rs->{chunkData}, 16);
                my $ret = $rs->{fio}->fileDeltaRxNext(undef, undef)
                       || $rs->{fio}->fileDeltaRxDone($md4digest, $phase);
                if ( $ret == 1 ) {
                    if ( $phase == 1 ) {
                        $rs->log("MD4 does't agree: fatal error on #$fileNum ($f->{name})");
                        last;
                    }
                    $rs->log("Must redo $fileNum ($f->{name})\n")
			if ( $rs->{logLevel} >= 2 );
                    print($fh "redo $fileNum\n");
                }
                last;
            } elsif ( $len > 0x80000000 ) {
                $len = 0xffffffff - $len;
                my $ret = $rs->{fio}->fileDeltaRxNext($len, undef);
            } else {
		return -1 if ( $rs->getChunk($len) < 0 );
                $d = unpack("a$len", $rs->{chunkData});
		$rs->{chunkData} = substr($rs->{chunkData}, $len);
                my $ret = $rs->{fio}->fileDeltaRxNext(undef, $d);
            }
        }

        #
        # If this is 2nd phase, then set the attributes just for this file
        #
	$rs->{fio}->attribSet($f, 1) if ( $phase == 1 );
    }
    #
    # Make any remaining dirs or special files
    #
    $rs->fileSpecialCreate($fileStart, undef) if ( $phase == 0 );

    $rs->log("Finished deltaGet phase $phase") if ( $rs->{logLevel} >= 2 );

    #
    # Finish up hardlinks at the very end
    #
    if ( $phase == 1 && $rs->{rsyncOpts}{"hard-links"} ) {
        my $cnt = $rs->{fileList}->count;
        for ( my $n = 0 ; $n < $cnt ; $n++ ) {
            my $f = $rs->{fileList}->get($n);
	    next if ( !defined($f) );
            next if ( !defined($f->{hlink}) || $f->{hlink_self} );
            if ( $rs->{clientCharset} ne "" ) {
                from_to($f->{name},  $rs->{clientCharset}, "utf8");
                from_to($f->{hlink}, $rs->{clientCharset}, "utf8");
            }
            if ( $rs->{fio}->makeHardLink($f, 1) ) {
                $rs->log("Error: makeHardlink($f->{name} -> $f->{hlink}) failed");
            }
        }
    }
}

sub fileListSend
{
    my($rs) = @_;

    $rs->{fileList} = File::RsyncP::FileList->new({
        preserve_uid        => $rs->{rsyncOpts}{owner},
        preserve_gid        => $rs->{rsyncOpts}{group},
        preserve_links      => $rs->{rsyncOpts}{links},
        preserve_devices    => $rs->{rsyncOpts}{devices},
        preserve_hard_links => $rs->{rsyncOpts}{"hard-links"},
        always_checksum     => $rs->{rsyncOpts}{checksum},
        protocol_version    => $rs->{protocol_version},
    });

    if ( $rs->{rsyncOpts}{"hard-links"} ) {
        $rs->{fileList}->init_hard_links();
    }

    $rs->{fio}->fileListSend($rs->{fileList}, sub { $rs->writeData($_[0]); });

    #
    # Send trailing null byte to indicate end of file list
    #
    $rs->writeData(pack("C", 0));

    #
    # Send io_error flag
    #
    $rs->writeData(pack("V", 0), 1);

    #
    # At this point io buffering should be switched off
    #
    # Sort and clean the file list
    #
    $rs->{fileList}->clean;

    #
    # Print out the sorted file list
    #
    if ( $rs->{logLevel} >= 4 ) {
        my $cnt = $rs->{fileList}->count;
        $rs->log("Sorted file list has $cnt entries");
        for ( my $n = 0 ; $n < $cnt ; $n++ ) {
            my $f = $rs->{fileList}->get($n);
	    next if ( !defined($f) );
            from_to($f->{name}, $rs->{clientCharset}, "utf8")
                                    if ( $rs->{clientCharset} ne "" );
            $rs->log("PostSortFile $n: $f->{name}");
        }
    }
}

sub write_sum_head
{
    my($rs, $fileNum, $blkCnt, $blkSize, $csumLen, $remainder) = @_;

    if ( $rs->{protocol_version} >= 27 ) {
        #
        # For protocols >= 27 we also send the csum length
        # for this file.
        #
        $rs->writeData(pack("V5",
                $fileNum,
                $blkCnt,
                $blkSize,
                $csumLen,
                $remainder), 0);
    } else {
        $rs->writeData(pack("V4",
                $fileNum,
                $blkCnt,
                $blkSize,
                $remainder), 0);
    }
}

sub abort
{
    my($rs, $reason, $timeout) = @_;

    $rs->{abort} = 1;
    $rs->{timeout} = $timeout if ( defined($timeout) );
    $rs->{abortReason} = $reason || "aborted by user request";
    kill($rs->{sigName2Num}{ALRM}, $rs->{childPID})
			     if ( defined($rs->{childPID}) );
    alarm($rs->{timeout}) if ( $rs->{timeout} );
}

sub statsGet
{
    my($rs, $fh) = @_;

    my($totalWritten, $totalRead, $totalSize) = (0, 0, 0);

    if ( $rs->getChunk(12) >= 0 ) {
	($totalWritten, $totalRead, $totalSize)
			= unpack("V3", $rs->{chunkData});
    }
    
    if ( defined($fh) ) {
	my $fioStats = $rs->{fio}->statsGet;
	my $dump = Data::Dumper->new([$fioStats], [qw(*fioStats)]);
	$dump->Terse(1);
	$dump->Indent(0);
	my $remoteErrCnt = 0 + $rs->{stats}{remoteErrCnt};
	print($fh "stats $totalWritten $totalRead $totalSize $remoteErrCnt ",
		  $dump->Dump, "\n");
    } else {
	$rs->{stats}{totalRead}    = $totalRead;
	$rs->{stats}{totalWritten} = $totalWritten;
	$rs->{stats}{totalSize}    = $totalSize;
	$rs->{stats}{fioStats}     = $rs->{fio}->statsGet;
    }
}

sub processStderr
{
    my($rs) = @_;

    my $stderr_data;
    sysread($rs->{fh_stderr}, $stderr_data, 65536);
    $rs->{stderr_data} .= $stderr_data;
    while ( $rs->{stderr_data} =~ /[\n\r]/ ) {
        (my $stderr_mesg, $rs->{stderr_data}) = split(/[\n\r]+/, $rs->{stderr_data}, 2);
        $rs->log($stderr_mesg);
    }
}

sub getData
{
    my($rs, $len) = @_;
    my($data);

    return -1 if ( $rs->{abort} );
    alarm($rs->{timeout}) if ( $rs->{timeout} );
    while ( length($rs->{readData}) < $len ) {
	return -1 if ( $rs->{abort} );
	my $ein;
	vec($ein, fileno($rs->{fh}), 1) = 1;
	vec($ein, fileno($rs->{fh_stderr}), 1) = 1 if ( defined($rs->{fh_stderr}) );
	select(my $rout = $ein, undef, $ein, undef);
        if ( defined($rs->{fh_stderr}) && vec($rout, fileno($rs->{fh_stderr}), 1) ) {
            $rs->processStderr();
            next;
        }
	return -1 if ( $rs->{abort} );
        sysread($rs->{fh}, $data, 65536);
        if ( length($data) == 0 ) {
            $rs->log("Read EOF: $!") if ( $rs->{logLevel} >= 1 );
	    return -1 if ( $rs->{abort} );
	    sysread($rs->{fh}, $data, 65536);
            $rs->log(sprintf("Tried again: got %d bytes", length($data)))
			if ( $rs->{logLevel} >= 1 );
            $rs->{abort}         = 1;
            $rs->{fatalError}    = 1;
            $rs->{fatalErrorMsg} = "Unable to read $len bytes";
            return -1;
        }
        if ( $rs->{logLevel} >= 10 ) {
            $rs->log("Receiving: " . unpack("H*", $data));
        }
        $rs->{readData} .= $data;
    }
}

sub getChunk
{
    my($rs, $len) = @_;

    $len ||= 1;
    while ( length($rs->{chunkData}) < $len ) {
	return -1 if ( $rs->getData(4) < 0 );
	my $d = unpack("V", $rs->{readData});
	$rs->{readData} = substr($rs->{readData}, 4);
	my $code = ($d >> 24) - 7;
	my $len  = $d & 0xffffff;
        return -1 if ( $rs->getData($len) < 0 );
	$d = substr($rs->{readData}, 0, $len);
	$rs->{readData} = substr($rs->{readData}, $len);
        if ( $code == 0 ) {
            $rs->{chunkData} .= $d;
        } else {
	    $d =~ s/[\n\r]+$//;
            from_to($d, $rs->{clientCharset}, "utf8")
                                    if ( $rs->{clientCharset} ne "" );
            $rs->log("Remote[$code]: $d");
            if ( $code == 1
                    || $d =~ /^file has vanished: /
                ) {
                $rs->{stats}{remoteErrCnt}++
            }
        }
    }
}

sub getLine
{
    my($rs) = @_;

    while ( 1 ) {
	if ( $rs->{readData} =~ /(.*?)[\n\r]+(.*)/s ) {
	    $rs->{readData} = $2;
	    return $1;
	}
	return if ( $rs->getData(length($rs->{readData}) + 1) < 0 );
    }
}

sub writeData
{
    my($rs, $data, $flush) = @_;    

    $rs->{writeBuf} .= $data;
    $rs->writeFlush() if ( $flush || length($rs->{writeBuf}) > 32768 ); 
}

sub statsFinal
{
    my($rs) = @_;    

    $rs->{stats}{parentStats} = $rs->{fio}->statsGet
		    if ( !defined($rs->{stats}{parentStats}) );
    return $rs->{stats};
}

sub writeFlush
{
    my($rs) = @_;    

    my($FDread, $FDwrite);

    return if ( $rs->{abort} );
    alarm($rs->{timeout}) if ( $rs->{timeout} );
    while ( $rs->{writeBuf} ne "" ) {
	#(my $chunk, $rs->{writeBuf}) = unpack("a4092 a*", $rs->{writeBuf});
	#$chunk = pack("V", (7 << 24) | length($chunk)) . $chunk;
	vec($FDread, fileno($rs->{childFh}), 1) = 1   if ( defined($rs->{childFh}) );
	vec($FDread, fileno($rs->{fh_stderr}), 1) = 1 if ( defined($rs->{fh_stderr}) );
	vec($FDwrite, fileno($rs->{fh}), 1) = 1;
	my $ein = $FDread;
	vec($ein, fileno($rs->{fh}), 1) = 1;
	select(my $rout = $FDread, my $rwrite = $FDwrite, $ein, undef);
	if ( defined($rs->{childFh})
			&& vec($rout, fileno($rs->{childFh}), 1) ) {
	    $rs->pollChild(0);
	}
        if ( defined($rs->{fh_stderr}) && vec($rout, fileno($rs->{fh_stderr}), 1) ) {
            $rs->processStderr();
            next;
        }
	return if ( $rs->{abort} );
	if ( vec($rwrite, fileno($rs->{fh}), 1) ) {
	    my $n = syswrite($rs->{fh}, $rs->{writeBuf});
	    if ( $n <= 0 ) {
		return $rs->log(sprintf("Can't write %d bytes to socket",
					  length($rs->{writeBuf})));
	    }
	    if ( $rs->{logLevel} >= 10 ) {
		my $chunk = substr($rs->{writeBuf}, 0, $n);
		$rs->log("Sending: " . unpack("H*", $chunk));
	    }
	    $rs->{writeBuf} = substr($rs->{writeBuf}, $n);
	}
    }
}

#
# Default log handler
#
sub logHandler
{
    my($str) = @_;

    print(STDERR $str, "\n");
}

sub log
{
    my($rs, @logStr) = @_;    

    foreach my $str ( @logStr ) {
	next if ( $str eq "" );
	$rs->{logHandler}->($str);
    }
}

#
# Escape shell meta-characters with backslashes.
# This should be applied to each argument seperately, not an
# entire shell command.
#
sub shellEscape
{
    my($self, $cmd) = @_;

    $cmd =~ s/([][;&()<>{}|^\n\r\t *\$\\'"`?])/\\$1/g;
    return $cmd;
}

1;

__END__

=head1 NAME

File::RsyncP - Perl Rsync client

=head1 SYNOPSIS

    use File::RsyncP;

    my $rs = File::RsyncP->new({
                logLevel   => 1,
                rsyncCmd   => "/bin/rsync",
                rsyncArgs  => [
                        "--numeric-ids",
                        "--perms",
                        "--owner",
                        "--group",
                        "--devices",
                        "--links",
                        "--ignore-times",
                        "--block-size=700",
                        "--relative",
                        "--recursive",
                        "-v",
                    ],
            });

    #
    # Receive files from remote srcDirectory to local destDirectory
    # by running rsyncCmd with rsyncArgs.
    #
    $rs->remoteStart(1, srcDirectory);
    $rs->go(destDirectory);
    $rs->serverClose;

    #
    # Send files to remote destDirectory from local srcDirectory
    # by running rsyncCmd with rsyncArgs.
    #
    $rs->remoteStart(0, destDirectory);
    $rs->go(srcDirectory);
    $rs->serverClose;

    #
    # Receive files from a remote module to local destDirectory by
    # connecting to an rsyncd server.  ($module is the name from
    # /etc/rsyncd.conf.)
    #
    my $port = 873;
    $rs->serverConnect($host, $port);
    $rs->serverService($module, $authUser, $authPasswd, 0);
    $rs->serverStart(1, ".");
    $rs->go(destDirectory);
    $rs->serverClose;

    #
    # Get finals stats.  This is a hashref containing elements
    # totalRead, totalWritten, totalSize, plus whatever the FileIO
    # module might add.
    #
    my $stats = $rs->statsFinal;

=head1 DESCRIPTION

File::RsyncP is a perl implementation of an Rsync client.  It is
compatible with Rsync 2.5.5 - 2.6.3 (protocol versions 26-28).
It can send or receive files, either by running rsync on the remote
machine, or connecting to an rsyncd deamon on the remote machine.

What use is File::RsyncP?  The main purpose is that File::RsyncP
separates all file system I/O into a separate module, which can
be replaced by any module of your own design.  This allows rsync 
interfaces to non-filesystem data types (eg: databases) to be
developed with relative ease.

File::RsyncP was initially written to provide an Rsync interface
for BackupPC, L<http://backuppc.sourceforge.net>.  See BackupPC
for programming examples.

File::RsyncP does not yet provide a command-line interface that
mimics native Rsync.  Instead it provides an API that makes it
possible to write simple scripts that talk to rsync or rsyncd.

The File::RsyncP::FileIO module contains the default file system access
functions.  File::RsyncP::FileIO may be subclassed or replaced by a
custom module to provide access to non-filesystem data types.

=head2 Getting Started

First some background.  When you run rsync is parses its command-line
arguments, then it either connects to a remote rsyncd daemon, or
runs an rsync on the remote machine via ssh or rsh.  At this point
there are two rsync processes: the one you invoked and the one
on the remote machine.  The one on the local machine is called
the client, and the one on the remote machine is the server.
One side (either the client or server) will send files and the
other will receive files.  The sending rsync generates a file 
list and sends it to the receiving side.  The receiving rsync
will fork a child process.

File::RsyncP does not (yet) have a command-line script that mimics
rsync's startup processing.  Think of File::RsyncP as one level below
the command-line rsync.  File::RsyncP implements the client side
of the connection, and File::RsyncP knows how to run the remote
side (eg, via rsh or ssh) or to connect to a remote rsyncd daemon.
File::RsyncP automatically adds the internal --server and --sender
options (if necessary) to the options passed to the remote rsync.

To initiate any rsync session the File::RsyncP->new function
should be called.  It takes a hashref of parameters:

=over 4

=item logLevel

An integer level of verbosity.  Zero means be quiet, 1 will give some
general information, 2 will some output per file, higher values give
more output.  10 will include byte dumps of all data read/written,
which will make the log output huge.

=item rsyncCmd

The command to run the remote peer of rsync.  By default the
rsyncArgs are appended to the rsyncCmd to create the complete
command before it is run.  This behavior is affected by rsyncCmdType.

rsyncCmd can either be a single string giving the path of the rsync
command to run (eg: /bin/rsync) or a list containing the command and
arguments, eg:

    rsyncCmd => [qw(
        /bin/ssh -l user host /bin/rsync
    )],

or:

    rsyncCmd => ["/bin/ssh", "-l", $user, $host, "/bin/rsync"],

Also, rsyncCmd can also be set to a code reference (ie: a perl sub).
In this case the code is called without arguments or other processing.
It is up to the perl code you supply to exec() the remote rsync.

This option is ignored if you are connecting to an rsyncd daemon.

=item rsyncCmdType

By default the complete remote rsync command is created by taking
rsyncCmd and appending rsyncArgs.  This beavhior can be modified
by specifying certain values for rsyncCmdType:

=over 4

=item 'full'

rsyncCmd is taken to be the complete command, including all
rsync arguments.  It is the caller's responsibility to build the
correct remote rsync command, togheter will all the rsync arguments.
You still need to specify rsyncArgs, so the local File::RsyncP knows
how to behave.

=item 'shell'

rsyncArgs are shell escaped before appending to rsyncCmd.

=back

This option is ignored if you are connecting to an rsyncd daemon.

=item rsyncArgs

A list of rsync arguments.  The full remote rsync command that is run
will be rsyncCmd appended with --server (and optionally --sender if the
remote is a sender) and finally all of rsyncArgs.

=item protocol_version

What we advertize our protocol version to be.  Default is 28.

=item logHandler

A subroutine reference to a function that handles all the log 
messages.  The default is a subroutine that prints the messages
to STDERR.

=item pidHandler

An optional subroutine reference to a function that expects two
integers: the pid of the rsync process (ie: the pid on the local
machine that is likely ssh) and the child pid when we are receiving
files.  If defined, this function is called once when the rsync
process is forked, and again when the child is forked during
receive.

=item fio

The file IO object that will handle all the file system IO.
The default is File::RsyncP::FileIO->new.

This can be replaced with a new module of your choice, or you
can subclass File::RsyncP::FileIO.

=item timeout

Timeout in seconds for IO.  Default is 0, meaning no timeout.
Uses alarm() and it is the caller's responsbility to catch the
alarm signal.

=item doPartial

If set, a partial rsync is done.  This is to support resuming full
backups in BackupPC.  When doPartial is set, the --ignore-times
option can be set on a per-file basis.  On each file in the
file list, File::RsyncP::FileIO->ignoreAttrOnFile() is called
on each file, and this returns whether or not attributes should
be ignored on that file.  If ignoreAttrOnFile() returns 1 then
it's as though --ignore-times was set for that file.

=back

An example of calling File::RsyncP->new is:

    my $rs = File::RsyncP->new({
                logLevel   => 1,
                rsyncCmd => ["/bin/rsh", $host,  "-l", $user, "/bin/rsync"],
                rsyncArgs  => [
                        "--numeric-ids",
                        "--perms",
                        "--owner",
                        "--group",
                        "--devices",
                        "--links",
                        "--ignore-times",
                        "--block-size=700",
                        "--relative",
                        "--recursive",
                        "-v",
                    ],
            });

A fuller example showing most of the parameters and qw() for the
rsyncArgs is:

    my $rs = File::RsyncP->new({
                logLevel   => 1,
                rsyncCmd => ["/bin/rsh", $host,  "-l", $user, "/bin/rsync"],
                rsyncArgs  => [qw(
                        --numeric-ids
                        --perms
                        --owner
                        --group
                        --devices
                        --links
                        --ignore-times
                        --block-size=700
                        --relative
                        --recursive
                        -v
                    )],
                logHandler => sub {
			my($str) = @_;    
			print MyHandler "log: $str\n";
		    };
                fio        => File::RsyncP::FileIO->new({
                                logLevel   => 1,
                            });

            });

=head2 Talking to a remote Rsync

File::RsyncP can talk to a remote rsync using this sequence of
functions:

=over 4

=item remoteStart(remoteSend, remoteDir)

Starts the remote server by executing the command specified
in the rsyncCmd parameter to File::RsyncP->new, together with
the rsyncArgs.

If the client is receiving files from the server then remoteSend should
be non-zero and remoteDir is the source directory on the remote machine.
If the client is sending files to the remote server then remoteSend should
be zero and remoteDir is the destination directory on the remote machine.
Returns undef on success and non-zero on error.

=item go(localDir)

Run the client rsync.  localDir is the source directory on the
local machine if the client is sending files, or it is the
destination directory on the local machine if the client is
receiving files.  Returns undef on success.

=item serverClose()

Call this after go() to finish up.  Returns undef on success.

=item statsFinal()

This can be optionally called to pickup the transfer stats.  It
returns a hashref containing elements totalRead, totalWritten,
totalSize, plus whatever the FileIO module might add.

=item abort()

Call this function to abort the transfer.

=back

An example of sending files to a remote rsync is:

    #
    # Send files to remote destDirectory from local srcDirectory
    # by running rsyncCmd with rsyncArgs.
    #
    $rs->remoteStart(0, destDirectory);
    $rs->go(srcDirectory);
    $rs->serverClose;

An example of receiving files from a remote rsync is:

    #
    # Receive files from remote srcDirectory to local destDirectory
    # by running rsyncCmd with rsyncArgs.
    #
    $rs->remoteStart(1, srcDirectory);
    $rs->go(destDirectory);
    $rs->serverClose;

=head2 Talking to a remote Rsync daemon

File::RsyncP can connect to a remote Rsync daemon using this
sequence of functions:

=over 4

=item serverConnect(host, port)

Connect to the Rsync daemon on the given string host and integer
port. The port argument is optional and it defaults to 873. On
error serverConnect returns a string error message. On success it
returns undef.

=item serverService(module, authUser, authPasswd, authRequired)

Specify which module to use (a "module" is the symbolic name that
appears inside "[...]" /etc/rsyncd.conf), the user's credentials
(authUser and authPasswd) and whether authorization is mandatory
(authRequired). If set to a non-zero value, authRequired ensures
that the remote Rsync daemon requires authentication.  If necessary,
this is to ensure that you don't connect to an insecure Rsync daemon.
The auth arguments are optional if the selected rsyncd module doesn't
require authentication.

See the rsyncd.conf manual page for more information.  For example, if a
host called navajo had a /etc/rsyncd.conf contains these lines:

   [test]
           path = /data/test
           comment = test module
           auth users = craig, celia
           secrets file = /etc/rsyncd.secrets

and /etc/rsyncd.secrets contained:

    craig:xxx

then you could connect to this rsyncd using:

    $rs->serverConnect("navajo", 873);
    $rs->serverService("test", "craig", "xxx", 0);

The value of the authRequired argument doesn't matter in this case.

On error serverService returns a string error message.
On success it returns undef.

=item serverStart(remoteSend, remoteDir)

Starts the remote server.  If the client is receiving files from
the server then remoteSend should be non-zero.  If the client is
sending files to the remote server then remoteSend should be zero.
The remoteDir typically starts with the module name, followed by
any directory below the module.  Or remoteDir can be just "."
to refer to the top-level module directory.
Returns undef on success.

=item go(localDir)

Run the client rsync.  localDir is the source directory on the
local machine if the client is sending files, or it is the
destination directory on the local machine if the client is
receiving files.  Returns undef on success.

=item serverClose()

Call this after go() to finish up.  Returns undef on success.

=item abort()

Call this function to abort the transfer.

=back

An example of sending files to a remote rsyncd daemon is:

    #
    # Send files to a remote module from a local srcDirectory by
    # connecting to an rsyncd server.  ($module is the name from
    # /etc/rsyncd.conf.)
    #
    my $port = 873;
    $rs->serverConnect($host, $port);
    $rs->serverService($module, $authUser, $authPasswd);
    $rs->serverStart(0, ".");
    $rs->go(srcDirectory);
    $rs->serverClose;

An example of receiving files from a remote rsyncd daemon is:

    #
    # Receive files from a remote module to local destDirectory by
    # connecting to an rsyncd server.  ($module is the name from
    # /etc/rsyncd.conf.)
    #
    my $port = 873;
    $rs->serverConnect($host, $port);
    $rs->serverService($module, $authUser, $authPasswd);
    $rs->serverStart(1, ".");
    $rs->go(destDirectory);
    $rs->serverClose;

=head1 LIMITATIONS

The initial version of File::RsyncP (0.10) has a number of limitations:

=over 4

=item *

File::RsyncP only implements a modest subset of Rsync options and
features.  In particular, as of 0.10 only these options are supported:

        --numeric-ids
        --perms|-p
        --owner|-o
        --group|-g
        --devices|D
        --links|-l
        --ignore-times|I
        --block-size=i
        --verbose|-v
        --recursive|-r
        --relative|-R

Hardlinks are currently not supported.  Other options that only
affect the remote side will work correctly since they are passed
to the remote Rsync unchanged.

=item *

Also, --relative semantics are not implemented to match rsync,
and the trailing "/" behavior of rsync (meaning directory contents,
not the directory itself) are not implemented in File::RsyncP.

=item *

File::RsyncP does not yet provide a command-line interface that mimics
native Rsync.

=item *

File::RsyncP might work with slightly earlier versions of Rsync
but has not been tested.  It certainly will not work with antique
versions of Rsync.

=item *

File::RsyncP does not compute file deltas (ie: it behaves as though
--whole-file is specified) or implement exclude or include options
when sending files.  File::RsyncP does handle file deltas and exclude
and include options when receiving files.

=item *

File::RsyncP does not yet implement server functionality (acting like
the remote end of a connection or a daemon).  Since the protocol is
relatively symmetric this is not difficult to add, so it should appear
in a future version.

=back

=head1 AUTHOR

File::RsyncP::FileList was written by Craig Barratt
<cbarratt@users.sourceforge.net> based on rsync 2.5.5.

Rsync was written by Andrew Tridgell <tridge@samba.org>
and Paul Mackerras.  It is available under a GPL license.
See http://rsync.samba.org.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License in the
LICENSE file along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.

=head1 SEE ALSO

See L<http://perlrsync.sourceforge.net> for File::RsyncP's SourceForge
home page.

See L<File::RsyncP::FileIO>, L<File::RsyncP::Digest>, and
L<File::RsyncP::FileList>.

Also see BackupPC's lib/BackupPC/Xfer/Rsync.pm for other examples.

=cut
