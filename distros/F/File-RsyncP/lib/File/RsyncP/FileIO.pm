#============================================================= -*-perl-*-
#
# File::RsyncP::FileIO package
#
# DESCRIPTION
#   Provide file system IO for File::RsyncP.
#
# AUTHOR
#   Craig Barratt  <cbarratt@users.sourceforge.net>
#
# COPYRIGHT
#   File::RsyncP is Copyright (C) 2002  Craig Barratt.
#
#   Rsync is Copyright (C) 1996-2001 by Andrew Tridgell, 1996 by Paul
#   Mackerras, and 2001, 2002 by Martin Pool.
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

package File::RsyncP::FileIO;

use strict;
use File::RsyncP::Digest;
use File::Path;
use File::Find;

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
    my $self = bless {
        blockSize    => 700,
        logLevel     => 0,
        digest       => File::RsyncP::Digest->new($options->{protocol_version}),
        checksumSeed => 0,
	logHandler   => \&logHandler,
	%$options,
    }, $class;
    return $self;
}

sub blockSize
{
    my($fio, $value) = @_;

    $fio->{blockSize} = $value if ( defined($value) );
    return $fio->{blockSize};
}

#
# We publish our version to File::RsyncP.  This is so File::RsyncP
# can provide backward compatibility to older FileIO code.
#
# Versions:
#
#   undef or 1:  protocol version 26, no hardlinks
#   2:           protocol version 28, supports hardlinks
#
sub version
{
    return 2;
}

sub preserve_hard_links
{   
    my($fio, $value) = @_;

    $fio->{preserve_hard_links} = $value if ( defined($value) );
    return $fio->{preserve_hard_links};
}

sub protocol_version
{
    my($fio, $value) = @_;

    if ( defined($value) ) {
        $fio->{protocol_version} = $value;
        $fio->{digest}->protocol($fio->{protocol_version});
    }
    return $fio->{protocol_version};
}

sub logHandlerSet
{
    my($fio, $sub) = @_;
    $fio->{logHandler} = $sub;
}

#
# Given a remote name, return the local name
#
sub localName
{
    my($fio, $name) = @_;

    return $name if ( !defined($fio->{localDir})
	   	   && !defined($fio->{remoteDir}) );
    if ( substr($name, 0, length($fio->{remoteDir})) eq $fio->{remoteDir} ) {
	substr($name, 0, length($fio->{remoteDir})) = $fio->{localDir};
    }
    return $name;
}

#
# Setup rsync checksum computation for the given file.
#
sub csumStart
{
    my($fio, $f, $needMD4) = @_;
    local(*F);
    my $localName = $fio->localName($f->{name});

    $fio->{file} = $f;
    $fio->csumEnd if ( defined($fio->{fh}) );
    return if ( !-f $localName || -l $localName );
    if ( !open(F, $localName) ) {
        $fio->log("Can't open $localName");
        return -1;
    }
    if ( $needMD4) {
	$fio->{csumDigest}
                    = File::RsyncP::Digest->new($fio->{protocol_version});
	$fio->{csumDigest}->add(pack("V", $fio->{checksumSeed}));
    } else {
	delete($fio->{csumDigest});
    }
    $fio->{fh} = *F;
}

sub csumGet
{
    my($fio, $num, $csumLen, $blockSize) = @_;
    my($fileData);

    $num     ||= 100;
    $csumLen ||= 16;

    return if ( !defined($fio->{fh}) );
    if ( sysread($fio->{fh}, $fileData, $blockSize * $num) <= 0 ) {
        return;
    }
    $fio->{csumDigest}->add($fileData) if ( defined($fio->{csumDigest}) );
    $fio->log(sprintf("%s: getting csum ($num,$csumLen,%d,0x%x)",
                            $fio->{file}{name},
                            length($fileData),
                            $fio->{checksumSeed}))
                if ( $fio->{logLevel} >= 10 );
    return $fio->{digest}->blockDigest($fileData, $blockSize,
                                         $csumLen, $fio->{checksumSeed});
}

sub csumEnd
{
    my($fio) = @_;

    return if ( !defined($fio->{fh}) );
    #
    # make sure we read the entire file for the file MD4 digest
    #
    if ( defined($fio->{csumDigest}) ) {
	while ( sysread($fio->{fh}, my $fileData, 65536) > 0 ) {
	    $fio->{csumDigest}->add($fileData);
	}
    }
    close($fio->{fh});
    delete($fio->{fh});
    return $fio->{csumDigest}->digest if ( defined($fio->{csumDigest}) );
}

sub readStart
{
    my($fio, $f) = @_;
    local(*F);
    my $localName = $fio->localName($f->{name});

    $fio->{file} = $f;
    $fio->readEnd if ( defined($fio->{fh}) );
    return if ( !-f $localName || -l $localName );
    if ( !open(F, $localName) ) {
        $fio->log("Can't open $localName");
        return;
    }
    $fio->{fh} = *F;
}

sub read
{
    my($fio, $num) = @_;
    my($fileData);

    $num ||= 32768;
    return if ( !defined($fio->{fh}) );
    if ( sysread($fio->{fh}, $fileData, $num) <= 0 ) {
        return $fio->readEnd;
    }
    return \$fileData;
}

sub readEnd
{
    my($fio) = @_;

    return if ( !defined($fio->{fh}) );
    close($fio->{fh});
    delete($fio->{fh});
}

sub checksumSeed
{
    my($fio, $checksumSeed) = @_;

    $fio->{checksumSeed} = $checksumSeed;
}

sub dirs
{
    my($fio, $localDir, $remoteDir) = @_;

    $fio->{localDir}  = $localDir;
    $fio->{remoteDir} = $remoteDir;
}

sub attribGet
{
    my($fio, $f) = @_;
    my $localName = $fio->localName($f->{name});

    my @s = stat($localName);
    return if ( !@s );
    return {
        mode  => $s[2],
        uid   => $s[4],
        gid   => $s[5],
        size  => $s[7],
        mtime => $s[9],
    }
}

#
# Set the attributes for a file.  Returns non-zero on error.
#
sub attribSet
{
    my($fio, $f, $placeHolder) = @_;
    my $ret;

    #
    # Ignore placeholder attribute sets: only do real ones.
    #
    return if ( $placeHolder );

    my $lName = $fio->localName($f->{name});
    my @s = stat($lName);
    my $a = {
        mode  => $s[2],
        uid   => $s[4],
        gid   => $s[5],
        size  => $s[7],
        atime => $s[8],
        mtime => $s[9],
    };
    $f->{atime} = $f->{mtime} if ( !defined($f->{atime}) );
    if ( ($f->{mode} & ~S_IFMT) != ($a->{mode} & ~S_IFMT)
		&& !chmod($f->{mode} & ~S_IFMT, $lName) ) {
        $fio->log(sprintf("Can't chmod(%s, 0%o)", $lName, $f->{mode}));
        $ret = -1;
    }
    if ( ($f->{uid} != $a->{uid} || $f->{gid} != $a->{gid})
	    && !chown($f->{uid}, $f->{gid}, $lName) ) {
        $fio->log("Can't chown($f->{uid}, $f->{gid}, $lName)");
        $ret = -1;
    }
    if ( ($f->{mtime} != $a->{mtime} || $f->{atime} != $a->{atime})
            && !utime($f->{atime}, $f->{mtime}, $lName) ) {
        $fio->log("Can't mtime($f->{atime}, $f->{mtime}, $lName)");
        $ret = -1;
    }
    return $ret;
}

sub statsGet
{
    my($fio) = @_;

    return {};
}

#
# Make a given directory.  Returns non-zero on error.
#
sub makePath
{
    my($fio, $f) = @_;
    my $localDir = $fio->localName($f->{name});

    return $fio->attribSet($f) if ( -d $localDir );
    File::Path::mkpath($localDir, 0, $f->{mode});
    return $fio->attribSet($f) if ( -d $localDir );
    $fio->log("Can't create directory $localDir");
    return -1;
}

#
# Make a special file.  Returns non-zero on error.
#
sub makeSpecial
{
    my($fio, $f) = @_;
    my $localPath = $fio->localName($f->{name});

    #
    # TODO: check if the special file is the same, then do nothing.
    # Should also create as a new unique name, then rename/unlink.
    #
    $fio->unlink($f->{name});
    if ( ($f->{mode} & S_IFMT) == S_IFCHR ) {
	my($major, $minor);

	$major = $f->{rdev} >> 8;
	$minor = $f->{rdev} & 0xff;
	return system("mknod $localPath c $major $minor");
    } elsif ( ($f->{mode} & S_IFMT) == S_IFBLK ) {
	my($major, $minor);

	$major = $f->{rdev} >> 8;
	$minor = $f->{rdev} & 0xff;
	return system("mknod $localPath b $major $minor");
    } elsif ( ($f->{mode} & S_IFMT) == S_IFLNK ) {
	if ( !symlink($f->{link}, $localPath) ) {
	    # error
	}
    } elsif ( ($f->{mode} & S_IFMT) == S_IFIFO ) {
	if ( system("mknod $localPath p") ) {
	    # error
	}
    }
    return $fio->attribSet($f);
}

#
# Make a hardlink.  Returns non-zero on error.
# This actually gets called twice for each hardlink.
# Once as the file list is processed, and again at
# the end.  This subroutine should decide whether it
# should do the hardlinks during the transer or at
# the end.  Normally they would be done at the end
# since the target might not exist until them.
# BackupPC does them as it goes (since it is just saving the
# hardlink info and not actually making hardlinks).
#
sub makeHardLink
{
    my($fio, $f, $end) = @_;

    #
    # In this case, only do hardlinks at the end.
    #
    return if ( !$end );
    my $localPath = $fio->localName($f->{name});
    my $destLink  = $fio->localName($f->{hlink});
    $fio->unlink($localPath) if ( -e $localPath );
    return !link($destLink, $localPath);
}


sub unlink
{
    my($fio, $path) = @_;
    my $localPath   = $fio->localName($path);

    return if ( !-e $localPath && !-l $localPath );
    if ( -d _ ) {
	rmtree($localPath);
    } else {
	CORE::unlink($localPath);
    }
}

sub ignoreAttrOnFile
{
    return undef;
}

#
# Start receive of file deltas for a particular file.
#
sub fileDeltaRxStart
{
    my($fio, $f, $cnt, $size, $remainder) = @_;

    $fio->{rxFile}      = $f;           # file attributes
    $fio->{rxBlkCnt}    = $cnt;         # how many blocks we will receive
    $fio->{rxBlkSize}   = $size;        # block size
    $fio->{rxRemainder} = $remainder;   # size of the last block
    $fio->{rxMatchBlk}  = 0;            # current start of match
    $fio->{rxMatchNext} = 0;            # current next block of match
    $fio->{rxSize}      = 0;            # size of received file
    if ( $fio->{rxFile}{size} != ($cnt > 0
				 ? ($cnt - 1) * $size + $remainder
				 : 0) ) {
        $fio->{rxMatchBlk} = undef;     # size different, so no file match
        $fio->log("$fio->{rxFile}{name}: size doesn't match"
                  . " ($fio->{rxFile}{size})")
                        if ( $fio->{logLevel} >= 5 );
    }
    delete($fio->{rxInFd});
    delete($fio->{rxOutFd});
    delete($fio->{rxDigest});
    $fio->{rxFile}{localName} = $fio->localName($fio->{rxFile}{name});
}

#
# Process the next file delta for the current file.  Returns 0 if ok,
# -1 if not.  Must be called with either a block number, $blk, or new data,
# $newData, (not both) defined.
#
sub fileDeltaRxNext
{
    my($fio, $blk, $newData) = @_;

    if ( defined($blk) ) {
        if ( defined($fio->{rxMatchBlk}) && $fio->{rxMatchNext} == $blk ) {
            #
            # got the next block in order; just keep track.
            #
            $fio->{rxMatchNext}++;
            return;
        }
    }
    my $newDataLen = length($newData);
    $fio->log("$fio->{rxFile}{name}: blk=$blk, newData=$newDataLen,"
        . " rxMatchBlk=$fio->{rxMatchBlk}, rxMatchNext=$fio->{rxMatchNext}")
		    if ( $fio->{logLevel} >= 8 );
    if ( !defined($fio->{rxOutFd}) ) {
	#
	# maybe the file has no changes
	#
	if ( $fio->{rxMatchNext} == $fio->{rxBlkCnt}
		&& !defined($blk) && !defined($newData) ) {
	    #$fio->log("$fio->{rxFile}{name}: file is unchanged");
	    #		    if ( $fio->{logLevel} >= 8 );
	    return;
	}

        #
        # need to open a temporary output file where we will build the
        # new version.
        #
        local(*F);
        my $rxTmpFile;
        for ( my $i = 0 ; ; $i++ ) {
            $rxTmpFile = "$fio->{rxFile}{localName}__tmp__$$.$i";
            last if ( !-e $rxTmpFile );
        }
        if ( !open(F, ">$rxTmpFile") ) {
            $fio->log("Can't open/create $rxTmpFile");
            return -1;
        }
        $fio->log("$fio->{rxFile}{name}: opening tmp output file $rxTmpFile")
                        if ( $fio->{logLevel} >= 10 );
        $fio->{rxOutFd} = *F;
        $fio->{rxTmpFile} = $rxTmpFile;

        $fio->{rxDigest} = File::RsyncP::Digest->new($fio->{protocol_version});
        $fio->{rxDigest}->add(pack("V", $fio->{checksumSeed}));
    }
    if ( defined($fio->{rxMatchBlk})
                && $fio->{rxMatchBlk} != $fio->{rxMatchNext} ) {
        #
        # need to copy the sequence of blocks that matched
        #
        if ( !defined($fio->{rxInFd}) ) {
            if ( open(F, "$fio->{rxFile}{localName}") ) {
                $fio->{rxInFd} = *F;
            } else {
                $fio->log("Unable to open $fio->{rxFile}{localName}");
                return -1;
            }
        }
	my $lastBlk = $fio->{rxMatchNext} - 1;
        $fio->log("$fio->{rxFile}{name}: writing blocks $fio->{rxMatchBlk}.."
                  . "$lastBlk")
                        if ( $fio->{logLevel} >= 10 );
        my $seekPosn = $fio->{rxMatchBlk} * $fio->{rxBlkSize};
        if ( !sysseek($fio->{rxInFd}, $seekPosn, 0) ) {
            $fio->log("Unable to seek $fio->{rxFile}{localName} to $seekPosn");
            return -1;
        }
        my $cnt = $fio->{rxMatchNext} - $fio->{rxMatchBlk};
        my($thisCnt, $len, $data);
        for ( my $i = 0 ; $i < $cnt ; $i += $thisCnt ) {
            $thisCnt = $cnt - $i;
            $thisCnt = 512 if ( $thisCnt > 512 );
            if ( $fio->{rxMatchBlk} + $i + $thisCnt == $fio->{rxBlkCnt} ) {
                $len = ($thisCnt - 1) * $fio->{rxBlkSize} + $fio->{rxRemainder};
            } else {
                $len = $thisCnt * $fio->{rxBlkSize};
            }
            if ( sysread($fio->{rxInFd}, $data, $len) != $len ) {
                $fio->log("Unable to read $len bytes from"
                          . " $fio->{rxFile}{localName} ($i,$thisCnt,$fio->{rxBlkCnt})");
                return -1;
            }
            if ( syswrite($fio->{rxOutFd}, $data) != $len ) {
                $fio->log("Unable to write $len bytes to"
                          . " $fio->{rxTmpFile}");
            }
            $fio->{rxDigest}->add($data);
	    $fio->{rxSize} += length($data);
        }
        $fio->{rxMatchBlk} = undef;
    }
    if ( defined($blk) ) {
        #
        # Remember the new block number
        #
        $fio->{rxMatchBlk}  = $blk;
        $fio->{rxMatchNext} = $blk + 1;
    }
    if ( defined($newData) ) {
        #
        # Write the new chunk
        #
        my $len = length($newData);
        $fio->log("$fio->{rxFile}{name}: writing $len bytes new data")
                        if ( $fio->{logLevel} >= 10 );
        if ( syswrite($fio->{rxOutFd}, $newData) != $len ) {
            $fio->log("Unable to write $len bytes to $fio->{rxTmpFile}");
            return -1;
        }
        $fio->{rxDigest}->add($newData);
	$fio->{rxSize} += length($newData);
    }
    return;
}

#
# Finish up the current receive file.  Returns undef if ok, -1 if not.
# Returns 1 if the md4 digest doesn't match.
#
sub fileDeltaRxDone
{
    my($fio, $md4) = @_;

    if ( !defined($fio->{rxDigest}) ) {
        local(*F);
        #
        # File was exact match, but we still need to verify the
        # MD4 checksum.  Therefore open and read the file.
        #
        $fio->{rxDigest} = File::RsyncP::Digest->new($fio->{protocol_version});
        $fio->{rxDigest}->add(pack("V", $fio->{checksumSeed}));
        if ( open(F, $fio->{rxFile}{localName}) ) {
            $fio->{rxInFd} = *F;
	    while ( sysread($fio->{rxInFd}, my $data, 4 * 65536) > 0 ) {
		$fio->{rxDigest}->add($data);
		$fio->{rxSize} += length($data);
	    }
        } else {
	    # error
	}
        $fio->log("$fio->{rxFile}{name}: got exact match")
                        if ( $fio->{logLevel} >= 5 );
    }
    close($fio->{rxInFd})  if ( defined($fio->{rxInFd}) );
    close($fio->{rxOutFd}) if ( defined($fio->{rxOutFd}) );
    my $newDigest = $fio->{rxDigest}->digest;
    if ( $fio->{logLevel} >= 3 ) {
        my $md4Str = unpack("H*", $md4);
        my $newStr = unpack("H*", $newDigest);
        $fio->log("$fio->{rxFile}{name}: got digests $md4Str vs $newStr")
    }
    if ( $md4 eq $newDigest ) {
        #
        # Nothing to do if there is no output file
        #
        if ( !defined($fio->{rxOutFd}) ) {
            $fio->log("$fio->{rxFile}{name}: nothing to do")
                        if ( $fio->{logLevel} >= 5 );
	    return $fio->attribSet($fio->{rxFile});
        }

        #
        # First rename the original file (in case the rename below fails)
        # to a unique temporary name.
        #
	my $oldFile;
	if ( -e $fio->{rxFile}{localName} ) {
	    for ( my $i = 0 ; ; $i++ ) {
		$oldFile = "$fio->{rxFile}{localName}__old__$$.$i";
		last if ( !-e $oldFile );
	    }
	    $fio->log("$fio->{rxFile}{name}: unlinking/renaming")
			if ( $fio->{logLevel} >= 5 );
	    if ( !rename($fio->{rxFile}{localName}, $oldFile) ) {
		$fio->log("Can't rename $fio->{rxFile}{localName}"
			  . " to $oldFile");
		CORE::unlink($fio->{rxTmpFile});
		return -1;
	    }
	}
        if ( !rename($fio->{rxTmpFile}, $fio->{rxFile}{localName}) ) {
            #
            # Restore old file
            #
            if ( !rename($oldFile, $fio->{rxFile}{localName}) ) {
                $fio->log("Can't retore original file $oldFile after rename"
                          . " of $fio->{rxTmpFile} failed");
            } else {
                $fio->log("Can't rename $fio->{rxTmpFile} to"
                          . " $fio->{rxFile}{localName}");
            }
            return -1;
        }
	if ( defined($oldFile) && CORE::unlink($oldFile) != 1 ) {
            $fio->log("Can't unlink old file $oldFile");
            return -1;
        }
    } else {
        $fio->log("$fio->{rxFile}{name}: md4 doesn't match")
                    if ( $fio->{logLevel} >= 1 );
        CORE::unlink($fio->{rxTmpFile}) if ( defined($fio->{rxTmpFile}) );
        return 1;
    }
    delete($fio->{rxDigest});
    $fio->{rxFile}{size} = $fio->{rxSize};
    return $fio->attribSet($fio->{rxFile});
}

sub fileListEltSend
{
    my($fio, $name, $fList, $outputFunc) = @_;
    my @s;
    my $extra = {};

    (my $n = $name) =~ s/^\Q$fio->{localDir}/$fio->{remoteDir}/;
    if ( -l $name ) {
	@s = lstat($name);
	$extra = {
	    %$extra,
            link => readlink($name),
        };
    } else {
	@s = stat($name);
    }
    if ( $fio->{preserve_hard_links}
            && ($s[2] & S_IFMT) == S_IFREG
            && ($fio->{protocol_version} < 27 || $s[3] > 1) ) {
	$extra = {
	    %$extra,
            dev   => $s[0],
            inode => $s[1],
        };
    }
    $fio->log("fileList send $name (remote=$n)") if ( $fio->{logLevel} >= 3 );
    $fList->encode({
            name  => $n,
            mode  => $s[2],
            uid   => $s[4],
            gid   => $s[5],
            rdev  => $s[6],
            size  => $s[7],
            mtime => $s[9],
	    %$extra,
        });
    &$outputFunc($fList->encodeData);
}

sub fileListSend
{
    my($fio, $flist, $outputFunc) = @_;

    find({wanted => sub {
                $fio->fileListEltSend($File::Find::name, $flist, $outputFunc);
          },
          no_chdir => 1
      }, $fio->{localDir});
}

sub finish
{
    my($fio, $isChild) = @_;

    return;
}

#
# Default log handler
#
sub logHandler
{
    my($str) = @_;

    print(STDERR $str, "\n");
}

#
# Handle one or more log messages
#
sub log
{
    my($fio, @logStr) = @_;

    foreach my $str ( @logStr ) {
        next if ( $str eq "" );
        $fio->{logHandler}->($str);
    }
}

1;
__END__

=head1 NAME

File::RsyncP::FileIO - Perl Rsync client file system IO

=head1 SYNOPSIS

    use File::RsyncP::FileIO;

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

=head1 DESCRIPTION

File::RsyncP::FileIO contains all of the file system access functions
needed by File::RsyncP.  This functionality is relegated to this
module so it can be subclassed or replaced by different code for
applications where an rsync interface is provided for non-file system
data (eg: databases).

File::RsyncP::FileIO provides the following functions.

=head2 Setup and utility functions

=over 4

=item new({ options... })

Creates a new File::RsyncP::FileIO object.  The single argument is
a hashref of options:

=over 4

=item blockSize

Defaults to 700.  Can be set later using the blockSize function.

=item logLevel

Defaults to 0.  Controls the verbosity of FileIO operations.

=item digest

Defaults to File::RsyncP::Digest->new.  No need to override.

=item checksumSeed

The checksum seed used in digest calculations.  Defaults to 0.
The server-side Rsync generates a checksum seed and sends it to
the client.  This value is usually set later, after the checksum
seed is received from the remote rsync, via the checksumSeed function.

=item logHandler

A subroutine reference to a function that handles all the log
messages.  The default is a subroutine that prints the messages
to STDERR.

=back

=item blockSize($value)

Set the block size to the new value, in case it wasn't set via the
blockSize option to new().

=item checksumSeed($seed)

Set the checksum seed used in digest calculations to the new value.
Usually this value isn't known when new() is called, so it is necessary
to set it later via this function.

=item logHandlerSet

Set the log handler callback function.  Usually this value is specified
via new(), but it can be changed later via this function.

=item dirs($localDir, $remoteDir)

Specify the local and remote directories.

=item log(@msg)

Save one (or more) messages for logging purposes.

=item statsGet

Return an optional hashref of statistics compiled by the FileIO object.
These values are opaquely passed up to File::RsyncP.

=item finish($isChild)

Do any necessary finish-up processing.  The $isChild argument is true
if this is the child process (remember the receiving side has two
processes: the child receives the file deltas while the parent
generates the block digests).

=back

=head2 Checksum computation functions

=over 4

=item csumStart($f, $needMD4)

Get ready to generate block checksums for the given file.  The argument
is a hashref typically returned by File::RsyncP::FileList->get.
Typically this opens the underlying file and creates a
File::RsyncP::Digest object.  If $needMD4 is non-zero, then csumEnd()
will return the file MD4 digest.

=item csumGet($num, $csumLen, $blockSize)

Return $num bkocks work of checksums with the MD4 checksum length of
$csumLen (typically 2 or 16), with a block size of $blockSize.
Typically this reads the file and calls File::RsyncP::Digest->blockDigest.

=item csumEnd()

Finish up the checksum calculation.  Typically closes the underlying file.
Note that csumStart, csumGet, csumEnd are called in strict order so they
don't need to be reentrant (ie: there is only one csum done at a time).
If csumStart() was called with $needMD4 then csumEnd() will return the
file MD4 digest.

=back

=head2 File reading functions

There are used for sending files (currently sending files doesn't
implement deltas; it behaves as though --whole-file was specified):

=over 4

=item readStart($f)

Get ready to read the given file.  The argument is a hashref typically
returned by File::RsyncP::FileList->get.
Typically this opens the underlying file.

=item read($num)

Read $num bytes from the file.

=item readEnd()

Finish up the read operation.  Typically closes the underlying file.
Note that readStart, readGet, readEnd are called in strict order so they
don't need to be reentrant (ie: there is only one read done at a time).

=back

=head2 File operations

=over 4

=item attribGet($f)

Return the attributes for the given file as a hashref.  The argument is a
hashref typically returned by File::RsyncP::FileList->get.

=item attribSet($f, $placeHolder)

Set the attributes for the given file.  The argument is a hashref
typically returned by File::RsyncP::FileList->get.  If $placeHolder
is true then don't do anything.  Returns undef on success.

=item makePath($f)

Create the directory specified by $f.  The argument is a hashref
typically returned by File::RsyncP::FileList->get.  Returns undef
on success.

=item makeSpecial($f)

Create the special file specified by $f.  The argument is a hashref
typically returned by File::RsyncP::FileList->get.  Returns undef on
success.

=item unlink($remotePath)

Unlink the file or directory corresponding to the given remote path.

=item ignoreAttrOnFile($f)

Normally should return undef, meaning use the default setting of
ignore-times.  Otherwise, if this function returns zero or non-zero, the
returned value  overrides the setting of ignore-times for this file.
The argument is a hashref typically returned by File::RsyncP::FileList->get.
See the doPartial option in File::RsyncP->new().

=back

=head2 File delta receiving functions

These functions are only called when we are receiving files.
They are called by the child process.

=over 4

=item fileDeltaRxStart($f, $cnt, $size, $remainder)

Start the receiving of file deltas for file $f, a hashref typically
returned by File::RsyncP::FileList->get.  The remaining arguments
are the number of blocks, size of blocks, and size of the last
(partial) block as generated by the parent on the receiving side
(they are not the values the new file on the sending side).
Returns undef on success.

=item fileDeltaRxNext($blk, $newData)

This function is called repeatedly as the file is constructed.
Exactly one of $blk and $newData are defined.  If $blk is defined
it is an integer that specifies which block of the original file
should be written at this point.  If $newData is defined, it is
literal data (that didn't match any blocks) that should be written
at this point.

=item fileDeltaRxDone($md4)

Finish processing of the file deltas for this file.  $md4 is the MD4
digest of the sent file.  It should be compared against the MD4 digest
of the reconstructed file.
Returns undef on success, 1 if the file's MD4 didn't agree (meaning
it should be repeated for phase 2), and negative on error.

=back

=head2 File list sending function

=over 4

=item fileListSend($fileList, $outputFunc)

Generate the file list (by calling $fileList->encode for every file
to be sent) and call the output function $outputFunc with the output
data by calling

    &$outputFunc($fileList->encodeData);

=back

=head1 AUTHOR

File::RsyncP::FileList was written by Craig Barratt
<cbarratt@users.sourceforge.net> based on rsync 2.5.5.

Rsync was written by Andrew Tridgell <tridge@samba.org>
and Paul Mackerras.  It is available under a GPL license.
See http://rsync.samba.org

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

See L<File::RsyncP>, L<File::RsyncP::Digest>, and
L<File::RsyncP::FileList>.

Also see BackupPC's lib/BackupPC/Xfer/RsyncFileIO.pm for an example
of another implementation of File::RsyncP::FileIO, in fact one that
is more tested than the default File::RsyncP::FileIO.pm.

=cut
