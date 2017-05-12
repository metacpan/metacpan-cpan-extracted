#
#  $Id: SmartTail.pm,v 4.66 2008/07/09 20:40:20 mprewitt Exp $
#
#  -----

=head1 NAME 

B<SmartTail.pm> Routines to smartly tail a file

=head1 SYNOPSIS

Special tail routines to tail a file, remember where you were, and
pick up from there again if necessary.

Called as:

    use File::SmartTail;
    $tail = new File::SmartTail(file1, file2, ...);
    while ($line = $tail->Tail()) {
        print $line;
    }

Or:

    $tail = new File::SmartTail;
    $tail->WatchFile(-file=>"file1",
        -type=>"UNIX-REMOTE",
        -host=>"lamachine",    
        -user=>"bozo",
        -rmtopts=>"-type UNIX -prefix appname",
        -rmtenv=>"PERL5LIB=/lib/foo FOO=bar",
        -date=>"parsed", -yrfmt=>4, -monthdir=>"../..",
        -timeout=>999,
        -request_timeout=>999,
        -prefix=>appname,
        -reset=>1);
    while ($line = GetLine(-doitfn=>\&YourFn)) {
        print $line;
    }

The format of the result is: 

    hostname:filename:line-of-data 

See WatchFile for detailed description of options.

=head1 DESCRIPTION

The File::SmartTail module provides functionality modeled on the UNIX tail
command, but enhanced with a variety of options, and the capability to
"remember" how far it has processed a file, between invocations. rtail.pl is
not normally used directly, but is invoked by a File::SmartTail object when
monitoring a file on a remote host. When monitoring files on a remote machine,
rtail.pl must be in the path of the owner of the process, on the remote machine.
Normally it is installed in /usr/local/bin. 

=head1 AUTHOR

DMJA, Inc <smarttail@dmja.com>

=head1 COPYRIGHT

Copyright (C) 2003-2015 DMJA, Inc, File::SmartTail comes with 
ABSOLUTELY NO WARRANTY. This is free software, and you are welcome to 
redistribute it and/or modify it under the same terms as Perl itself.
See the "The Artistic License" L<LICENSE> for more details.

=cut

package File::SmartTail;

use strict;
use vars qw( $VERSION );
use Fcntl;
use File::Basename;
use IO::Seekable;
use IO::File;
use IO::Socket;
use Time::Local;
use Sys::Hostname;
use File::SmartTail::Logger;
use File::SmartTail::DB;

$VERSION = (qw$Revision: 4.66 $)[1];

use vars qw(  $BATCHLIM $BEAT $BEATOUT $COUNT $DIRTY $MAX_RETRIES $SLEEP $TODAY $TOMORROW );

#
# Heartbeat frequency (seconds), heartbeat timeout interval (seconds), 
# maximum attempts to restart remote process ("your results may vary"),
#

$BEAT = 30;
$BEATOUT = 120;
$MAX_RETRIES = 6;
$SLEEP = 2;

$BATCHLIM = 100; # Chunk of records before running DoIt() if present.
$COUNT = 0;

#$BINDIR="/usr/local/bin";

$TODAY = fmtime(time, 4);
$TOMORROW = rolldate($TODAY, 4);

=head2 new

    $tail = new File::SmartTail($filename1, $filename2, ...)

or

    $tail = new File::SmartTail(-tietype=>$type, -statuskey=>$programname, -bindir=>$rtail_script_location, $filename1, $filename2, ...)

B<i-tietype> can be any class that can be tied to a hash like NDBM_File DB_File
SDBM_File.

Default statuskey is name of invoking program.

=cut

sub new {
    my $type = shift;

    my $self = bless {}, ref $type || $type;

    #
    # due to funny API, we do a funny thing here....
    # it's a hash; it's a list; what is it?
    #
    my $STATUSKEY;
    my $TIETYPE;
    my %args;
    @args{ @_ } = ();
    my %h = @_;
    if ( exists $h{-tietype} ) {
        if ($h{-tietype} =~ /NDBM/) {
            $TIETYPE = 'NDBM_File';
        } else {
            $TIETYPE = $h{-tietype};
        }
        delete @args{ '-tietype', $h{-tietype} };
    }
    if ( exists $h{-statuskey} ) {
        $h{-statuskey} and $STATUSKEY = $h{-statuskey};
        delete @args{ '-statuskey', $h{-statuskey} };
    }
    if ( exists $h{-bindir} ) {
        $self->{BINDIR} = $h{-bindir};
        delete @args{ '-bindir', $h{-bindir} };
    }
    #
    # remaining args in original order, in case order matters
    #
    my @parms = grep exists $args{$_}, @_;

    #
    #  Use a key to record where we are in the file.
    #
    $STATUSKEY or $STATUSKEY = $0;
    $STATUSKEY = basename($STATUSKEY);
    $STATUSKEY =~ s/\W/_/g;
    $STATUSKEY .= ":$>";

    $self->{DB} = File::SmartTail::DB->new( statuskey => $STATUSKEY, tietype => $TIETYPE );
    ###
    
    #
    #  Go ahead and open all the files.
    #
    foreach my $file ( @parms ) {
	$self->OpenFile( $file ) ||
	    die "Unable to tail file \"$file\" [$!].";
    }

    return $self;
}
    
=head2 Tail

    $tail->Tail()

or 

    $tail->Tail( @files ) (doesn't seem to be supported)

Format of the returned line is:

    $file1: line of file here.

As a degenerate case, $tail->Tail( $file ) will simply return the next
line without a need to manage or massage.

=cut
sub Tail {

    my $self = shift;

    #
    #  Now, read through the files.  If the file has stuff in its array,
    #  then start by returning stuff from there.  If it does not, then
    #  read some more into the file, parse it, and then return it.
    #  Otherwise, go on to the next file.
    #
    for ( ; ; ) {
	if ( $DIRTY && ! ( $COUNT++ % 10 ) ) {
	    $DIRTY = 0;
	    $self->{DB}->sync;
	}

	FILE: foreach my $file ( keys %{ $self->{file_data} } ) {
	    my $line;
	    if ( ! @{$self->{file_data}->{$file}->{array}} ) {
		#
		#  If there's nothing left on the array, then read something new in.
		#  This should never fail, I think.
		#
		my $length;
		SYSREAD: {
		    $length = $self->{file_data}->{$file}->{FILE}->sysread($line, 1024);
		    unless ( defined $length ) {
			next SYSREAD if $! =~ /^Interrupted/;
			die "sysread of $file failed [$!].\n";
		    }
		};

		if ( ! $length ) {
		    #
		    #  Hmmm...zero length here, perhaps we've been aged out?
		    #
		    my ( $inode, $size ) = (stat($file))[1,7];
		    if ( $self->{file_data}->{$file}->{inode} != $inode ||
			 $self->{file_data}->{$file}->{seek} > $size ) {
			#
			#  We've been aged (inode diff) or we've been truncated
			#  (our checkpoint is larger than the file.)
			#
			$self->OpenFile( $file ) ||
			    die "Unable to tail file \"$file\" [$!]\n";
		    }
		    #
		    #  In any case, we didn't read anything, so go to the next file.
		    #
		    next FILE;
		}

		#
		#  We read something!  But don't forget to add on anything we may have 
		#  read before. Build our array by splitting our latest read plus whatever
		#  is saved.
		#
		$self->{file_data}->{$file}->{array} = [ split( /^/m, $self->{file_data}->{$file}->{line} . $line) ];

		#
		#  If there's a leftover piece, then save it in the "line".  Otherwise,
		#  clear it out.
		#
		if ( substr($self->{file_data}->{$file}->{array}->[$#{$self->{file_data}->{$file}->{array}}],
			    -1, 1) ne "\n" ) {
		    $self->{file_data}->{$file}->{line} = pop @{$self->{file_data}->{$file}->{array}};
		    next unless @{$self->{file_data}->{$file}->{array}};
		} else {
		    undef $self->{file_data}->{$file}->{line};
		}
	    }
	    
	    #
	    #  If we make it here, then we have something on our array to return.
	    #  Increment our counter and sync up our disk file.
	    #
	    my $return = shift @{$self->{file_data}->{$file}->{"array"}};
	    $self->{file_data}->{$file}->{seek} += length($return);
	    if ($self->{DB}->{STATFILE}) {
		$self->{DB}->{STATUS}->{$file} = "$self->{file_data}->{$file}->{inode}:$self->{file_data}->{$file}->{seek}";
	    }
	    $DIRTY++;
	    return "$file:$return";
	}
	#
	#  Still here?  That means we redo the loop.
	#
	
	sleep $SLEEP;
    }
}

sub OpenFile {
    my( $self, $file ) = @_;
    #
    #  Give the file a moment to reappear if it's not there.
    #
    unless ( -r $file ) {
	sleep 10;
	unless ( -r $file ) {
	    $! = 2;
	    return undef;
	}
    }

    #
    #  Stat it, and see if it's the file we were last tailing if this
    #  is the first time we're trying to open the file.
    #
    my $foundfile = $file;
    if ($self->{DB}->{STATFILE}) {
	if ( ! $self->{file_data}->{$file}->{done} ) {
	    ( $self->{file_data}->{$file}->{inode}, $self->{file_data}->{$file}->{seek} ) = split(/:/, $self->{DB}->{STATUS}->{$file} );
	    my $inode = (stat($file))[1];
	    if ( $self->{file_data}->{$file}->{inode} &&
		 $inode != $self->{file_data}->{$file}->{inode} ) {
		
		#
		#  It's not where we left off.  Uh-oh - see if we can find the
		#  last inode we were on when we quit.
		#
		my ( $findfile, $dir, $item );
		$findfile = basename($file);
		$dir = dirname($file);
		opendir(DIR, $dir) || 
		    die "Unable to read directory $dir to search for previous file [$!].\n";
		foreach $item ( grep(/^$findfile\.\d+/, readdir DIR ) ) {
		    next unless (stat("$dir/$item"))[1] == $self->{file_data}->{$file}->{inode};
		    $foundfile = "$dir/$item";
		    last;
		}
	    }
	}
    }
    #
    #  Now, open the file.
    #
    $self->{file_data}->{$file}->{FILE} = new IO::File;

    #
    #  Did we find a temporary old ratty file to tail from?  Either
    #  way, get our current $inode and size.
    #
    $self->{file_data}->{$file}->{FILE}->open("< $foundfile") ||
	    die "Failed to open $file [$!].\n";
    my ( $inode, $size ) = (stat($foundfile))[1,7];

    $self->{file_data}->{$file}->{done}++;

    #
    #  Clear our array.
    #
    $self->{file_data}->{$file}->{array} = [ ];

    if ($self->{DB}->{STATFILE}) {
	if ( $inode == $self->{file_data}->{$file}->{inode} ) {
	    #
	    #  We've reopened the same file.  Skip ahead to count.
	    #
	    if ( $size >= $self->{file_data}->{$file}->{seek} &&
		 sysseek($self->{file_data}->{$file}->{FILE}, $self->{file_data}->{$file}->{seek}, 0 ) ) {
		#
		#  Successful read.  Let's return and be done.
		#
		return 1;
	    }
	}
	
	#
	#  We've opened a new file OR the above if failed and it's a truncated
	#  file, so we start as if we reopened the file anyway.
	#
	$self->{DB}->{STATUS}->{$file} = "$inode:0";
	$self->{DB}->sync;
    }
    $self->{file_data}->{$file}->{inode} = $inode;
    $self->{file_data}->{$file}->{seek} = 0;
    
    return 1;
}

sub OpenFileWithOpts {
    my( $self, $key ) = @_;
    #
    #  Give the file a moment to reappear if it's not there.
    #
    my $filename = $self->{file_data}->{$key}->{opts}->{-current};
    LOG()->debug( "filename: $filename" );
    unless ( -r $filename ) {
	sleep 10;
	unless ( -r $filename ) {
	    $! = 2;
	    return undef;
	}
    }
    
    my $hostname = $self->{file_data}->{$key}->{opts}->{-host};
    my $prefix = $self->{file_data}->{$key}->{opts}->{-prefix};
    #
    #  Stat it, and see if it's the file we were last tailing if this
    #  is the first time we're trying to open the file.
    #
    my $foundfile = $filename;
    if ($self->{DB}->{STATFILE}) {
	if ( ! $self->{file_data}->{$key}->{done} ) {
            LOG()->debug( sub {
                my $db_key = "$prefix:$hostname:$filename";
                my $db_val = $self->{DB}->{STATUS}->{$db_key};
                "$db_key => $db_val";
            } );
	    ( $self->{file_data}->{$key}->{inode}, $self->{file_data}->{$key}->{seek} ) = split(/:/, $self->{DB}->{STATUS}->{"$prefix:$hostname:$filename"} );
	    my $inode = (stat($filename))[1];
            LOG()->debug( "filename: $filename; inode: $inode" );
	    if ( $self->{file_data}->{$key}->{inode} &&
		 $inode != $self->{file_data}->{$key}->{inode} ) {
		
		#
		#  It's not where we left off.  Uh-oh - see if we can find the
		#  last inode we were on when we quit.
		#
                LOG()->debug( "filename: $filename; inode: $inode; self->{file_data}->{$key}->{inode}:$self->{file_data}->{$key}->{inode} " );
		my ( $findfile, $dir, $item );
		$findfile = basename($filename);
		$dir = dirname($filename);
		opendir(DIR, $dir) || 
		    die "Unable to read directory $dir to search for previous file [$!].\n";
		foreach $item ( grep(/^$findfile\.\d+/, readdir DIR ) ) {
		    next unless (stat("$dir/$item"))[1] == $self->{file_data}->{$key}->{inode};
		    $foundfile = "$dir/$item";
		    last;
		}
	    }
	}
	
    }
    #
    #  Now, open the file.
    #
    if (defined $self->{file_data}->{$key}->{FILE}) {
	undef $self->{file_data}->{$key}->{FILE};
    }
    $self->{file_data}->{$key}->{FILE} = new IO::File;

    #
    #  Did we find a temporary old ratty file to tail from?  Either
    #  way, get our current $inode and size.
    #
    LOG()->debug( qq( open("< $foundfile") ) );
    $self->{file_data}->{$key}->{FILE}->open("< $foundfile") ||
	    die "Failed to open $foundfile [$!].\n";
    my ( $inode, $size ) = (stat($foundfile))[1,7];

    LOG()->debug( "foundfile: $foundfile; inode: $inode; size: $size" );
    LOG()->debug( "key: $key; inode: $self->{file_data}->{$key}->{inode}; seek: $self->{file_data}->{$key}->{seek}" );

    $self->{file_data}->{$key}->{done}++;

    #
    #  Clear our array.
    #
    $self->{file_data}->{$key}->{array} = [ ];
    if ($self->{DB}->{STATFILE}) {
	
	if ( $inode == $self->{file_data}->{$key}->{inode} ) {
	    #
	    #  We've reopened the same file.  Skip ahead to count.
	    #
            LOG()->debug( "We've reopened the same file.  Skip ahead to count." );
	    if ( $size >= $self->{file_data}->{$key}->{seek} &&
		 sysseek($self->{file_data}->{$key}->{FILE}, $self->{file_data}->{$key}->{seek}, 0 ) ) {
		#
		#  Successful read.  Let's return and be done.
		#
		LOG()->debug( "Successful seek.  Let's return and be done." );
		return 1;
	    }
	}
	
	#
	#  We've opened a new file OR the above if failed and it's a truncated
	#  file, so we start as if we reopened the file anyway.
	#
        LOG()->debug( "We've opened a new file OR same file, but it has been truncated. Start as if we reopened the file anyway." );
	$self->{DB}->{STATUS}->{"$prefix:$hostname:$filename"} = "$inode:0";
	$self->{DB}->sync;
    }
    $self->{file_data}->{$key}->{inode} = $inode;
    $self->{file_data}->{$key}->{seek} = 0;
    
    LOG()->debug( sub { $self->{DB}->DumpStatus } );

    return 1;
}

=head2 Watchfile

    WatchFile(-option1=>"value1", -option2=>"value2", ...)

=over 4

B<Required Options:>

=over 4

=item -file=>"filename"
  
The name of a file to watch.

=back

B<Other Options:>

=over 4

=item -type=>"UNIX" (default, i.e. if omitted) or "UNIX-REMOTE" 

=item -rmtsh=>"ssh" (default)  valid values are "rsh" or "ssh"

=item -host=>"host"

Required for type "UNIX-REMOTE" unless file name is of the form host:filename (similar to rcp). 

=item -rmtopts=>"-opt1 val1 -opt2 val2"

Any flags that should be passed to the remote process. Since these become command-line args, they should have the form "-opt1 val1 -opt2 val2 ...". 

=item -rmtenv=>"ENV1=val1 ENV1=val2"

Any environment variables that should be set on the remote before runnign the
remote process.

=item -date=>'parsed' or 'gz'
    
indicates special date-related file
processing. B<parsed> is used with files having dates in their
name. B<gz> is used for files which are archived so that a new
open call is needed to continue monitoring. Other archive
file extensions can be used in theory, but the file name is
assumed to be of the format name.date.extension
               
=item -yrfmt=>2 or 4

For files having dates in their name, how
many digits are used to represent the year. The default
is 2, but a value of 4 may be set with this option.
    
=item -monthdir=>$relative_path 

for files having dates in their
name, to indicate, where applicable, the relative position
in the path of the month's directory. E.g. ".."
    
=item -timeout=>$secs 

Used for an application-specific timeout. If the file does not grow during
the specified interval, a message of the form
host1:file1:_timeout_999999999 is returned, where 999999999 is
secs-in-epoch (UNIX timestamp). 
   
=item -request_timeout=>$secs 

Used for an application-specific timeout. If no data is available within the
specified interval from the time the request was made (GetLine() was called), a
message of the form host1:file1:_timeout_999999999 is returned, where 999999999
is secs-in-epoch (UNIX timestamp). 
   
=back

B<Internal:>

=over 4

=item -heartbeat=>"send" 

Set on the child process for a "UNIX-REMOTE" file. Similarly, flags will
be set in the parent process to listen for the heartbeat.

When processing a UNIX-REMOTE file, the child process is set to send an
internal heartbeat message, and the local process is set to receive them.
The heartbeat messages are of the form host1:file1:_heartbeat_999999999
where 999999999 is secs-in-epoch (UNIX timestamp). 

=item -current 

Holds the current file name. This is used when
files with date-suffixed names roll, since the hash entry is
still keyed by the original file name.
               
=item -prefix 

a prefix for the filestatus file, which is used to
keep track of the seek pointer between invocations. The default
is the path of the calling application.
    
=item -reset=>1 

will ignore the status file that normally keeps
track of Tail's progress through the file, including between
invocations

=item -clear=>1 

like -reset, but will remove the file.

=back

=back

=cut
sub WatchFile {
    my ($self, %opts) = @_;
    
    %opts = %{$self->ResolveOpts(%opts)};
    my $key = $opts{-file};
    $self->{file_data}->{$key}->{opts} = \%opts;

    if ($opts{-type} eq "UNIX"){
	$self->OpenFileWithOpts( $key ) ||
	    die "Unable to tail \"$key\" [$!]\n";
    }
    elsif ($opts{-type} eq "UNIX-REMOTE") {
	$self->OpenRemote( %opts ) ||
	    die "Unable to tail \"$key\" [$!]\n";
    }
    else {
	die "Unknown file type \"$opts{-type}\".\n";
    }
}

sub OpenRemote {
    my ($self, %opts) = @_;
    my $userflag = "";
    my $key = $opts{-file};
    my $filename = $opts{-current};
    my $hostname = $opts{-host};
    my $prefix = $opts{-prefix};
    my $rmtenv;
    my $ssh = $opts{-rmtsh} || $self->{file_data}->{$key}->{opts}->{-rmtsh} || "ssh";
    my ($conn_try, $port, $port_try, $ssh_try, $sock, $tmpfile);

    if ($opts{-user}) {
	$userflag = "-l $opts{-user}";
    }
    my $rmtopts = $opts{-rmtopts} || "";
    #
    # Must have a file type for the remotely tailed file.
    #
    if (!$rmtopts =~ /\B-type\s+\w/) {
	return undef;
    }


    if ($opts{-rmtenv}) {
        $rmtenv = "/usr/bin/env $opts{-rmtenv}";
    }
    #
    # Set the filestatus file prefix for the remote process
    # (if it isn't set already).
    #
    $rmtopts = $rmtopts . " -prefix $prefix"
	unless $rmtopts =~ /\B-prefix\s+\S+/;

    #
    # Set the hostname for the remote process (if it isn't set already).
    #
    $rmtopts = $rmtopts . " -host $hostname "
	unless $rmtopts =~ /\B-host\s+\w/;

    #
    # Send a heartbeat from the remote process and receive it here.
    #
    $rmtopts = $rmtopts . " -heartbeat send "
	unless $rmtopts =~ /\B-heartbeat\s+send\b/;

    #
    # Set the statuskey for the remote process (if it isn't set already).
    #
    ( my $statuskey_base = $self->{DB}->{STATUSKEY} ) =~ s/:.*$//;
    $rmtopts = $rmtopts . " -statuskey rtail_$statuskey_base "
	unless $rmtopts =~ /\B-statuskey\s+\w/;

    $opts{-heartbeat} = "recv"
	unless $opts{-heartbeat} && $opts{-heartbeat} eq "recv";
    
    # Kill child process if necessary.
    $self->Kill($key);

    $ssh_try = 1;
    $port_try = 1;
    my $fallback_ssh = 0;
    RSHELL: {
	$tmpfile = new IO::File;
	my $cmd = "$ssh $hostname -n $userflag $rmtenv $self->{BINDIR}rtail.pl -file $filename $rmtopts < /dev/null |";
        LOG()->debug( qq( Preparing to open "$cmd") );
	unless ($self->{file_data}->{$key}->{child} = $tmpfile->open($cmd)) {
	    warn "Attempt $ssh_try to open of $ssh pipe for $key failed [$!]  , child status [$?]\n";
	    if ( ($! =~ /^Interrupted|^Resource|^Bad file/) and ++$ssh_try < 7) {
		$self->Kill($key);
		undef $tmpfile;
		sleep 2;
		redo RSHELL;
	    } else {
                if ($fallback_ssh) {
                    die "Failure opening $ssh pipe for $key [$!] after $ssh_try attempts [ERR_SSH].\n";
                } else {
                    my $old_ssh = $ssh;
                    if ($ssh eq "ssh") {
                        $ssh = "rsh";
                    } else {
                        $ssh = "ssh";
                    }
                    warn "Failure opening $old_ssh pipe for $key [$!] after $ssh_try attempts [ERR_SSH]. Trying to $ssh.\n";
                    $ssh_try = 0;
                    $fallback_ssh = 1;
                    redo RSHELL;
                }
	    }
	}
    
        unless (fcntl( $tmpfile, F_SETFL, fcntl($tmpfile, F_GETFL, 0) | O_NONBLOCK )) { 
            die "fcntl of $ssh pipe for $key failed [$!] [ERR_FCNTL].\n";
        }

	PORT: {
	    $port = <$tmpfile>;
            $port_try++;
	    if (not defined $port) {
		if ($! =~ /^Interrupted/ and $port_try < 20) {
		    redo PORT;
		} elsif ($! =~ /^Resource/ and $port_try < 20) {
		    sleep 2;
		    redo PORT;
		} else {
                    if ($fallback_ssh) {
                        die "Failure reading port from $ssh [$!] after $port_try attempts [ERR_RETRIES].\n";
                    } else {
                        my $old_ssh = $ssh;
                        if ($ssh eq "ssh") {
                            $ssh = "rsh";
                        } else {
                            $ssh = "ssh";
                        }
                        warn "Failure opening $old_ssh pipe for $key [$!] after $ssh_try attempts [ERR_SSH]. Trying to $ssh.\n";
                        $ssh_try = 0;
                        $port_try = 0;
                        $fallback_ssh = 1;
                        redo RSHELL;
                    }
		}
	    } elsif ($port == 0) {
		die "Failure reading port from $ssh: 0 read after $port_try attempt(s) [ERR_EMPTY].\n" if $port_try > 20;
		sleep 2;
		redo RSHELL;
	    } elsif ($port =~ /^\d+$/) {
		last RSHELL; # Success
	    } else {
		die "$cmd failed: $port [ERR_REMOTE]\n"; # Remote error
	    }    
		     
	};
    };

    
    undef $tmpfile;

    if (defined $self->{file_data}->{$key}->{FILE}) {
	undef $self->{file_data}->{$key}->{FILE};
    }
    $conn_try = 0;
    CONNECT: {
	unless ($self->{file_data}->{$key}->{FILE} = 
		new IO::Socket::INET(PeerAddr =>$hostname,
				     PeerPort =>$port,
				     Proto =>'tcp')) {
	    $conn_try++;
	    warn "Failed creating socket for $key [$!], after $conn_try attempts\n";
	    if ( ($! =~ /^Interrupted|^Resource|^Bad file|^Connection/) and 
		 $conn_try < 6) {
		undef ($self->{file_data}->{$key}->{FILE});
		sleep 2;
		redo CONNECT;
	    } else {
		die "Failure creating socket for $key [$!], $conn_try attempt(s) [ERR_SOCKET].\n";
	    }
	}
    };

    unless ( fcntl( $self->{file_data}->{$key}->{FILE}, F_SETFL, 
		    fcntl($self->{file_data}->{$key}->{FILE}, F_GETFL, 0) | 
		    O_NONBLOCK ) ) {
	die "fcntl of socket for $key failed [$!] [ERR_SOCKFCNTL].\n";
    }

    $self->{file_data}->{$key}->{done}++;

    #
    #  Clear our array.
    #
    $self->{file_data}->{$key}->{array} = [ ];

    #
    # (Re)set 
    #
    # No inode for remote connections.
    $self->{file_data}->{$key}->{seek} = 0;
    if ($self->{DB}->{STATFILE}) {
	$self->{DB}->{STATUS}->{"$prefix:$hostname:$filename"} = "0:0";
	$self->{DB}->sync;
    }
    #
    # (Re)set heartbeat detection.
    #
    $self->{file_data}->{$key}->{heartbeat} = time;

    #
    # Add internal opts to object
    #
    $self->{file_data}->{$key}->{opts}->{-rmtopts} = $rmtopts;
    $self->{file_data}->{$key}->{opts}->{-heartbeat} = $opts{-heartbeat};
    return 1;
}

=head2 GetLine

Format of the returned line is:

    $hoste1:$file1: line of file here.

If a remote file is being followed, heartbeat messages of the form
$host1:$file1:_heartbeat_999999999, where 999999999 is secs-in-epoch
are returned.

If a set of file opts includes a -timeout, and there is no
activity on the file within the timeout interval, messages of the form
$host1:file1:_timeout_999999999 
are returned.

If a set of file opts includes a -request_timeout, and there is no data to be
returned within the timeout interval from the time that GetLine was called,
a message of the form $host1:file1:_timeout_999999999 is returned.

=cut
sub GetLine {

    my ($self, %doitfn) = @_;
    my ($now, $donefiles);
    my $request_mark;

    #
    # First time through set up index array that we will permute
    # to reduce bias toward the first files in the keys list.
    #
    unless ( defined $self->{KEYS} ) {
	$self->{KEYS} = [ keys %{ $self->{file_data} } ];
	$self->{FILECOUNT} = scalar @{ $self->{KEYS} };
    } else {
	push @{ $self->{KEYS} }, shift @{ $self->{KEYS} };
    }
    
    for ( ; ; ) {
        $request_mark ||= time();
	$COUNT++;
	if ( $DIRTY && ! ( $COUNT % 10 ) ) {
	    $DIRTY = 0;
	    $self->{DB}->sync;
	}
	
	$donefiles = $self->{FILECOUNT};

	#
	#  Now, read through the files.  If the file has stuff in its array,
	#  then start by returning stuff from there.  If it does not, then
	#  read some more into the file, parse it, and then return it.
	#  Otherwise, go on to the next file.
	#
	
	FILE: foreach my $key ( @{ $self->{KEYS} } ) {
	    my $line;
	    my $filename = $self->{file_data}->{$key}->{opts}->{-current};
	    my $host = $self->{file_data}->{$key}->{opts}->{-host};
	    my $prefix = $self->{file_data}->{$key}->{opts}->{-prefix};
	    # If the file has rolled, the name has changed, although it's
	    # still keyed by the original name.
	    if (exists $self->{file_data}->{$key}->{opts}->{-heartbeat} && 
                    $self->{file_data}->{$key}->{opts}->{-heartbeat} eq "send") {
		my $msg = $self->Heartbeat($key);
		if (defined $msg) {
		    return "$key:$msg";
		}
	    }
	    # If heartbeat fails and the retry limit is exceeded
	    # return message.
	    # $self->{file_data}->{$key}->{heartbeat} will be undefined.
	    elsif (exists $self->{file_data}->{$key}->{opts}->{-heartbeat} &&
                    $self->{file_data}->{$key}->{opts}->{-heartbeat} eq "recv") {
		my $msg = $self->CheckBeat($key);
		if (defined $msg) {
		    return "$key:$msg";
		}
	    }

	    if (exists $self->{file_data}->{$key}->{opts}{-timeout}) {
		my $msg = $self->CheckTimeout($key);
		if (defined $msg) {
		    return "$key:$msg";
		}

	    }

	    if (exists $self->{file_data}->{$key}->{opts}{-request_timeout}) {
		my $msg = $self->CheckRequestTimeout($key, $request_mark || time() );
		if (defined $msg) {
		    return "$key:$msg";
		}

	    }


	    if ( ! @{$self->{file_data}->{$key}->{array}} ) {
		#
		#  If there's nothing left on the array, then read something new in.
		#  This should never fail, I think.
		#
		my $length;
		SYSREAD: {
		    $length = $self->{file_data}->{$key}->{FILE}->sysread($line, 1024);
		    unless ( defined $length ) {
			if ($! =~ /^Interrupted/) {
			    redo SYSREAD;
			}
			elsif ($self->{file_data}->{$key}->{opts}->{-type} eq
			       "UNIX-REMOTE" &&   $! =~ /^Resource/) {
			    $donefiles--;
			    next FILE;
			    }
			else {
			    die "sysread of $filename failed [$!].\n";
			}
		    }
		};

		if ( ! $length ) {
		    #
		    #  Hmmm...zero length here, perhaps we've been aged out?
		    #
		    if ($self->{file_data}->{$key}->{opts}->{-type} eq "UNIX") {
			my ( $inode, $size ) = (stat($filename))[1,7];
			if ( $self->{file_data}->{$key}->{inode} != $inode ||
			     $self->{file_data}->{$key}->{seek} > $size ) {
			    #
			    #  We've been aged (inode diff) or we've been
			    # truncated (our checkpoint is larger than the
			    # file.) Pass the file key to OpenFileWithOpts,
			    # which may be different from the current name.
			    #
                            LOG()->debug( sub {
                                my $happened = $self->{file_data}->{$key}->{inode} != $inode ? 'aged' : 'truncated';
                                "File $filename has been $happened. OpenFileWithOpts( $key ).";
                            } );

			    $self->OpenFileWithOpts( $key ) ||
				die "Unable to tail file \"$filename\" [$!]\n";
                            #
                            # For a -request_timeout, don't count the time it
                            # took to OpenFileWithOpts(), or the SLEEP at the
                            # end of this loop.  That is, reset $request_mark.
                            #
                            LOG()->debug( sub {
                                'Undefining request_mark at ' . localtime();
                            } );
                            undef $request_mark;
			}

			if (exists $self->{file_data}->{$key}->{opts}->{-date}) {
			    # We use "rollover" to refer to files whose
			    # names change daily, and the parent process
			    # wants the current file.
			    #
			    # We use "archive" to refer to files whose names
			    # are constant, but the file itself is compressed
			    # or otherwise renamed.
			    #
			    if ($self->{file_data}->{$key}->{opts}->{-date} eq
				"parsed") {
				# Need to pass original key here, not current
				# name.
				my $msg = $self->RollFile($key);
				# Rollover: If a file named with the new date
				# has appeared, the return is
				# _rollover_999999999 where the numeric 
				# portion is seconds-in-epoch.
				# (1) the -timeout option is deleted by a
				# true timeout, but not by a rollover.
				# (2) Caller can detect new file name in
				# -current option after a rollover.
				# (3) The timed-out counter has been reset
				# by RollFile if the rollover succeeded.
				if (defined $msg) {
				    $filename = 
					$self->{file_data}->{$key}->{opts}->{-current};
				    return "$key:$msg";
				}
			    } else {
				my $msg = $self->ArchFile($key);
				# Archive: the value of -date in this case is
				# the file extension of the archived file.
				# Currrently the only name format supported is
				# filename.99999999.extension.
				# The returned line is:
				#                 _archived_999999999 where
				# the numeric portion is seconds-in-epoch.
				if (defined $msg) {
				    return "$key:$msg";
				}
			    }
			}
		    }
		    elsif ($self->{file_data}->{$key}->{opts}->{-type} eq 
			   "UNIX-REMOTE") {
			# Zero length does not necessarily mean a problem
			# for UNIX-REMOTE files. Only reopen if the
			# heartbeat fails.
			$donefiles--;
			next FILE;
		    }
		    else {
			die "Bogus file type\n";
		    }
		    
		    #
		    #  In any case, we didn't read anything, so go to the
		    # next FILE;
		    #
		    $donefiles--;
		    next FILE;
		}
		
		#
		#  We read something!  Mark the time if required.
		#  Don't forget to add on anything we may have read before.
		#  Build our array by splitting our latest read plus whatever
		#  is saved.
		#
		$now = time;
		if (exists $self->{file_data}->{$key}->{opts}{-timeout}) {
		    $self->{file_data}->{$key}->{filetime} = $now;
		}
		if (defined $self->{file_data}->{$key}->{heartbeat})  {
		    $self->{file_data}->{$key}->{heartbeat} = $now;
		}

		$self->{file_data}->{$key}->{array} = [ split( /^/m, $self->{file_data}->{$key}->{line} . $line) ];

		#
		#  If there's a leftover piece, then save it in the "line".  Otherwise,
		#  clear it out.
		#
		if ( substr($self->{file_data}->{$key}->{array}->[$#{$self->{file_data}->{$key}->{array}}],
			    -1, 1) ne "\n" ) {
		    $self->{file_data}->{$key}->{line} = pop @{$self->{file_data}->{$key}->{array}};
		    next unless @{$self->{file_data}->{$key}->{array}};
		} else {
		    undef $self->{file_data}->{$key}->{line};
		}
	    }
	    
	    #
	    #  If we make it here, then we have something on our array.
	    #  If it's a heartbeat,  continue (we marked it above).
	    #  Otherwise increment our counter, sync up our disk file,
	    #  and return the line.
	    #
	    my $return = shift @{$self->{file_data}->{$key}->{"array"}};
	    if ($return =~ /(_heartbeat_)(\d+)/) {
		$donefiles--;
		next FILE;
	    }

	    $DIRTY++;

	    if ($self->{file_data}->{$key}->{opts}->{-type} eq "UNIX-REMOTE") {
		my ($host, $file, $msg) = split(/:/, $return, 3);
		#
		# See comment at IsRollover().
		#
		my @roll = $self->IsRollover($msg);
		if ($roll[1]) {
		    $self->{file_data}->{$key}->{opts}->{-current} = $roll[0];
		}
		$self->{file_data}->{$key}->{seek} += length($msg);
		if ($self->{DB}->{STATFILE}) {
		    $self->{DB}->{STATUS}->{"$prefix:$host:$filename"} = 
			"$self->{file_data}->{$key}->{inode}:$self->{file_data}->{$key}->{seek}";
		}
		return "$key:$msg";
	    }
	    else {
		$self->{file_data}->{$key}->{seek} += length($return);
		if ($self->{DB}->{STATFILE}) {
		    $self->{DB}->{STATUS}->{"$prefix:$host:$filename"} = 
			"$self->{file_data}->{$key}->{inode}:$self->{file_data}->{$key}->{seek}";
		}
		return "$key:$return";
	    }
	}
	#
	#  Still here?  That means we redo the loop. But first ...
	#
	# Run the DoIt function every $BATCHLIM records.
	#
	
	if (! ($COUNT % $BATCHLIM)) {
	    if (%doitfn) {
		$doitfn{-doitfn}->(); # run it
	    }
	}
	#
	# Sleep only if all files are temporarily unavailable.
	#
	sleep ($SLEEP) unless $donefiles;
    }
}

=head2 Heartbeat

=cut
sub Heartbeat {
    my $self = shift;
    my $key = shift;
    my $now = time;
    if ($self->{file_data}->{$key}->{heartbeat} eq undef ||
	$self->{file_data}->{$key}->{heartbeat} < $now - $BEAT +$SLEEP) {
	my $msg = "_heartbeat_$now\n";
	$self->{file_data}->{$key}->{heartbeat} = $now;
	return $msg;
    }
    else {
	return undef;
    }
}

=head2 ResetHeartBeats

Use e.g. if monitor has been paused. Start checking for heartfailure
again now.

=cut
sub ResetHeartbeats {
    my $self = shift;
    my $now = time;
    foreach my $key ( keys %{ $self->{file_data} } ) {
	if ($self->{file_data}->{$key}->{opts}->{-heartbeat} eq 'recv') {
	    $self->{file_data}->{$key}->{heartbeat} = $now;
	}
    }
}

=head2 CheckBeat

=cut
sub CheckBeat{
    my $self = shift;
    my $key = shift;
    my $now = time;
    my $return = undef;

    if ($self->{file_data}->{$key}->{heartbeat} &&
	$now - $self->{file_data}->{$key}->{heartbeat} > $BEATOUT) {
	if ($self->{file_data}->{$key}->{retries}++ > $MAX_RETRIES) {
	    $self->{file_data}->{$key}->{FILE}->close();
	    $self->Kill($key);
	    undef $self->{file_data}->{$key}->{heartbeat};
	    $return = "_heartfailure_$now\n";
	}
	else {
	    sleep (2 ** $self->{file_data}->{$key}{retries});
	    $self->WatchFile(%{$self->{file_data}->{$key}->{opts}});
	}
    }
    return $return;
}

=head2 CheckTimeout

=cut
sub CheckTimeout {
    my $self = shift;
    my $key = shift;
    my $now = time;
    my $return = undef;
    $self->{file_data}->{$key}->{filetime} = $now 
	unless $self->{file_data}->{$key}->{filetime};
    if ($now - $self->{file_data}->{$key}->{filetime} >
	$self->{file_data}->{$key}->{opts}{-timeout} - $SLEEP) {
	delete $self->{file_data}->{$key}->{opts}->{-timeout};
	$return = "_timeout_$now\n";
    }
    return $return;
}

=head2 CheckRequestTimeout

=cut

sub CheckRequestTimeout {
    my $self = shift;
    my $key = shift;
    my $request_mark = shift;
    my $now = time();
    my $return = undef;

    if ($now - $request_mark > $self->{file_data}->{$key}->{opts}{-request_timeout} ) {
	$return = "_timeout_request_$now\n";
    }
    return $return;
}

=head2 Kill

=cut
sub Kill {
    my $self = shift;
    my $key = shift;
    if ($self->{file_data}->{$key}->{child}) {
	my $child = $self->{file_data}->{$key}->{child};
	kill 'TERM', $child;
	sleep 2;
	kill 0, $child &&
	    kill 'KILL', $child;
    }
}

=head2 ArchFile

=cut
sub ArchFile {
    my $self = shift;
    my $key = shift;
    my $return = undef;
    my $now = time;
    my $fname = $self->{file_data}->{$key}->{opts}->{-current};
    my $ext = $self->{file_data}->{$key}->{opts}->{-date};
    my $archname = "$fname.$TOMORROW.$ext";
    if (-r $archname) {
	$TODAY = $TOMORROW;
	$TOMORROW = rolldate ($TODAY, 4);
	#
	# Open the new file (with the same name)
	#
	if ($self->OpenFileWithOpts( $key ) ) {
	    $return = "_archived_$now\n";
	}
    }
    return $return;
}

=head2 RollFile

=cut
sub RollFile {
    my $self = shift;
    my $key = shift;
    my $return = undef;
    my $now = time;
    my ($base, $datepart, $dir, $monthdir, $name, $newdate, $newname, $pre, $yrfmt);
    $name = $self->{file_data}->{$key}->{opts}->{-current};
    $dir = dirname($name);
    $base = basename($name);
    $monthdir = $self->{file_data}->{$key}->{opts}->{-monthdir};
    $yrfmt = $self->{file_data}->{$key}->{opts}->{-yrfmt};
    if ($base =~ /(^[\/A-Za-z]*)([0-9]+)$/) {
	$pre = $1;
	$datepart = $2;
	$newdate = rolldate($datepart, $yrfmt);
	if (defined $monthdir) {
	    my $curym = int 0.01 * $datepart;
	    my $newym = int 0.01 * $newdate;
	    my @arr = split (/\//, $dir);
	    if ($curym ne $newym) {
		my $p = -1;
		my $i = 0;
		while (($p = index($monthdir, "..", $p)) > -1) {
		    $i++;
		    $p++;
		}
		die "RollFile cannot determine month directory.\n" if ($i < 0 or $i > $#arr);
	    @arr[scalar(@arr) - $i] = $newym;
	    $dir = join("\/", @arr);
	    }
	}
	$newname = "$dir/$pre$newdate";
	if (-r $newname) {
	    close($self->{file_data}->{$key}->{FILE});
	    $self->{file_data}->{$key}->{opts}->{-current} = $newname;
	    # (Re)initialize timed-out counter.
	    if ($self->{file_data}->{$key}->{timedout}) {
		$self->{file_data}->{$key}->{timedout} = 0;
	    }
	    # Reset {done} flag
	    if ($self->{file_data}->{$key}->{done}) {
		$self->{file_data}->{$key}->{done} = 0;
	    }
	    #
	    # Open the new file
	    #
	    $self->OpenFileWithOpts( $key )
		or return undef;
	    #
	    # 
	    #
	    $return = '_rollover_' . $now . '_' . $newname . '_';
	    return "$return\n";
	}
    }
    return undef;
}

sub rolldate {
    my $date = shift;
    my $yrfmt = shift; # positions we would like for the year in the result.
    my ($yr, $mon, $day, $newdate);
    $yr = int $date * 0.0001;
    $day = ($date % 10000) % 100;
    $mon = int 0.01 * ($date % 10000);
    #
    # Arbitrary choice to treat year numbers < 50 as in 2000s.
    #
    if ($yr < 100) {
	if ($yr < 50) {
	    $yr += 2000;
	}
	else {
	    $yr += 1900;
	}
    }
    my $time = timelocal(0, 0, 3, $day, ($mon - 1), $yr);
    $newdate = fmtime($time + 86400, $yrfmt);

    return $newdate;
}


=head2 Size

=cut
sub Size {
    my $self = shift;
    my $key = shift;
    if (exists $self->{file_data}->{$key}->{seek}) {
	return $self->{file_data}->{$key}->{seek};
    } else {
	return undef;
    }
}

#
# Format a seconds-in-epoch time as a date with 2 to 4 positions in the year
# Called as fmtime( $unixtime, 4 );
# Second parameter is optional and defaults to 2.
#
sub fmtime {
    my $time = shift;
    my $yrfmt = shift; # positions we would like for the year in the result.
    my ($fmt, $sec, $min, $hrs, $day, $mon, $yr, $newdate);

    ($sec, $min, $hrs, $day, $mon, $yr) = localtime ($time);
    $yrfmt = 2 
	unless $yrfmt && $yrfmt ge 2 && $yrfmt lt 5;
    $fmt = "%".$yrfmt.".u%2.u%2.u";
    $newdate = sprintf($fmt, (($yr + 1900) % 10 ** $yrfmt), ($mon + 1), $day);
    $newdate =~ s/ /0/g;  
    return $newdate;
}

=head2 Detecting Exception Notification

The following functions may be used to determine if a returned line
is a notification of exception conditions.

Called as: 

    $tail = new File::SmartTail;
    $line = $tail->GetLine();
    $tail->WatchFile(%options);
    ($host, $file, $rec) = split (/:/, $line, 3);
    if ($tail->IsFn($rec)) { # do what you like };

where IsFn represents one of the Is-prefixed functions below.
All of the IsFns return 1 if the named condition is present, else undef.

=head2 IsTimeout

An application timeout has been exceeded. 

=cut
sub IsTimeout {
    my $self = shift;
    my $line = shift;
    my $return = undef;
    if ($line =~ /(_timeout_)(\d+)/) {
	$return = 1;
    }
    
    return $return;
}

=head2 IsRequestTimeout

An application timeout has been exceeded. 

=cut
sub IsRequestTimeout {
    my $self = shift;
    my $line = shift;
    my $return = undef;
    if ($line =~ /(_timeout_request_)(\d+)/) {
	$return = 1;
    }
    
    return $return;
}

=head2 IsRollover

A -date=>'parsed' file has rolled to the next day. In array context, 
returns (newfilename, 1) if true

!Note: returns 1 in scalar context, and an array with elt 0 containing
the new filename in array context.

=cut
sub IsRollover {
    my $self = shift;
    my $line = shift;
    my $return = undef;
    if ($line =~ /(_rollover_)(\d+)(_)(.*)_$/) {
	$return = $4;
    }
    
    return ($return, defined($return));
}

=head2 IsArchived

A -date=>'gz' file has been gzip'd (archived). 

=cut
sub IsArchived {
    my $self = shift;
    my $line = shift;
    my $return = undef;
    if ($line =~ /(_archived_)(\d+)/) {
	$return = 1;
    }
    
    return $return;
}

=head2 IsHeartFailure

The internal heartbeat has not been detected for longer than the 
prescribed interval (currently 120 seconds). 

=cut
sub IsHeartFailure {
    my $self = shift;
    my $line = shift;
    my $return = undef;
    #
    # If the heartbeat is not received within the prescribed interval,
    # and the max retries are exhausted, a message is sent.
    if ($line =~ /(_heartfailure_)(\d+)/) {
	$return = 1;
    }
    
    return $return;
}

=head2 IsZipd

The file options include -date=>'gz' 

=cut
sub IsZipd {
    my %opts = @_;
    my $return = undef;
    if (%opts) {
	if ( ($opts{-date} eq 'gz') or
	     $opts{-rmtopts} =~ /-date\s+gz/ ) {
	    $return++;
	}
    }
    return $return;
}

# Nonmember functions:

# From given opts (minimum: -file=>filename) supply defaults as
# necessary to fill in key, filename, host, and type.

sub ResolveOpts {
    my $self = shift;
    my %opts = @_;
    # If we have hostname:filename, that's the key.
    # If we have -host and it's different, complain.
    # If no host is given use Sys::Hostname
    #
    # If no explicit -prefix, use the path name of the executing file.
    my ($tmpa, $tmpb) = split (/:/, $opts{-file}, 2);
    my ($key, $host, $filename);
    if (defined $tmpb) {
	$key = $opts{-file};
	$filename = $tmpb;
	if (exists $opts{-host}) {
	    if ($opts{-host} ne $tmpa) {
		die "Ambiguous host: -file => $opts{-file} and -host => $opts{-host}\n";
	    }
	} else {
	    $opts{-host} = $tmpa;
	}
    } else {
	$filename = $tmpa;
	$opts{-host} = hostname
	    unless (exists $opts{-host});
	$host = $opts{-host};
	$key = "$host:$filename";
	$opts{-file} = $key;
    }
    
    unless (exists $opts{-current}) {
	$opts{-current} = $filename
    }

    unless (exists $opts{-type}) {
	$opts{-type} = "UNIX";
    }

    unless (exists $opts{-rmtsh}) {
	$opts{-rmtsh} = "ssh";
    }

    $opts{-prefix} = normalize_prefix( $opts{-prefix} ) ;
#    unless (exists $opts{-prefix}) {
#	my @path = fileparse($0);
#	if ($path[1] eq "\.\/") {
#	    $path[1] = `pwd &2>&1`;
#	    chomp $path[1];
#	    $path[1] .= "\/";
#	}
#	$opts{-prefix} = $path[1] . $path[0] . $path[2];
#    }

    if (exists $opts{'-clear'}) {
	if (-f $self->{DB}->{STATFILE}) {
	    unlink $self->{DB}->{STATFILE} || die "Cannot unlink $self->{DB}->{STATFILE}";
	}
	$self->{DB}->{STATFILE} = "";
    } 
    if (exists $opts{'-reset'}) {
	$self->{DB}->{STATFILE}=""
    }

    if ( exists $opts{'-request_timeout'} ) {
        if ($opts{'-request_timeout'} < 1) {
            $opts{'-request_timeout'} = 1;
        }
    }

    return \%opts;
}

sub FileType {
    my %opts = @_;
    my $return = undef;

    if (%opts) {
	$return = $opts{-type};
    }

    return $return;
}

sub HostUser {
    my %opts = @_;
    my $return = undef;

    if (%opts) {
	my @array;
	push @array,  $opts{-host};
	push @array, $opts{-user};
	$return = \@array;
    }
    return $return;
}

sub Filename {
    my %opts = @_;
    my $return = undef;

    if (%opts){
	$return = $opts{-current};
    }

    return $return;
}

sub Key {
    my %opts = @_;
    my $return = undef;

    if (%opts){
	$return = $opts{-file};
    }

    return $return;
}

sub DateOpt {
    my %opts = @_;
    my $return = undef;

    if (%opts){
	$return = $opts{-date};
    }

    return $return;
}

sub RmtOpts {
    my %opts = @_;
    my $return = undef;
    if (%opts) {
	$return = $opts{-rmtopts};
    }
    return $return;
}

{
    my $v;
    sub LOG {
        $v ||= require File::SmartTail::Logger && File::SmartTail::Logger::LOG();
    }
}

#
# Attempt to normalize path of prefix.
# 
# If an arbitrary string (not the name of an existing file) is passed as -prefix, 
#       return input untouched, for backwards compatibility.
# If an existing filename is passed as -prefix (and for default of $0),
#       resolve any symlinks in path.
#
sub normalize_prefix {
    my $prefix = shift || $0;

    -e $prefix or
        return $prefix;
    require File::Basename;
    my ($name,$path,$suffix) = File::Basename::fileparse( $prefix );
    $name = '' unless $name;
    $path = '' unless $path;
    $suffix = '' unless $suffix;
    require Cwd;
    $path = Cwd::abs_path( $path ) or
        return $prefix;
    $path =~ m{/$} or $path .= '/';
    return $path . $name . $suffix;
}

=head1 Examples

=head2 Regular local file 

    use File::SmartTail;

    $file = "/tmp/foo"
    $tail = new File::SmartTail($file);

    while($line = $tail->Tail) {
        print $line;
    }

or 

    use File::SmartTail;

    $file = "/tmp/foo"
    $tail = new File::SmartTail();
    $tail->WatchFile(-file=>$file);

    while($line = $tail->GetLine) {
        print $line;
    }

=head2 Regular remote file on two hosts 

    use File::SmartTail;

    $file = "/tmp/foo";

    $tail = new File::SmartTail;
    $tail->WatchFile(-file=>$file, -type=>"UNIX-REMOTE", -host=>"guinness", -rmtopts
            =>"-type UNIX");
    $tail->WatchFile(-file=>$file, -type=>"UNIX-REMOTE", -host=>"corona", -rmtopts=>
            "-type UNIX");

    while($line = $tail->GetLine()) {
        print $line;
    }

=head2 Local file, with timeout 

    use File::SmartTail;

    $file = "/tmp/foo";

    $tail = new File::SmartTail;
    $tail->WatchFile(-file=>$file, -type=>"UNIX", -timeout=>70);

    while($line = $tail->GetLine()) {
        print $line;
    }

=head2 Remote file named by date, 4-digit year, having month directory 

    use File::SmartTail;

    $file = "guinness:/tmp/foo20011114";

    $tail = new File::SmartTail;
    $tail->WatchFile(-file=>$file, -type=>"UNIX-REMOTE", -rmtopts=>'-date parsed -yrfmt 4 -monthdir ".." -type UNIX');

    while($line = $tail->GetLine()) {
            print $line;


=cut

1;
