# Declare our package
package Filesys::Virtual::Async::inMemory;
use strict; use warnings;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.02';

# Set our parent
use base 'Filesys::Virtual::Async';

# get some system constants
use Errno qw( :POSIX );			# ENOENT EISDIR etc
use Fcntl qw( :DEFAULT :mode :seek );	# S_IFREG S_IFDIR, O_SYNC O_LARGEFILE etc

# get some handy stuff
use File::Spec;

# create our virtual FHs
use IO::Scalar;

# Set some constants
BEGIN {
	if ( ! defined &DEBUG ) { *DEBUG = sub () { 0 } }
}

# creates a new instance
sub new {
	my $class = shift;

	# The options hash
	my %opt;

	# Support passing in a hash ref or a regular hash
	if ( ( @_ & 1 ) and ref $_[0] and ref( $_[0] ) eq 'HASH' ) {
		%opt = %{ $_[0] };
	} else {
		# Sanity checking
		if ( @_ & 1 ) {
			warn __PACKAGE__ . ' requires an even number of options passed to new()';
			return;
		}

		%opt = @_;
	}

	# lowercase keys
	%opt = map { lc($_) => $opt{$_} } keys %opt;

	# set the readonly mode
	if ( exists $opt{'readonly'} and defined $opt{'readonly'} ) {
		$opt{'readonly'} = $opt{'readonly'} ? 1 : 0;
	} else {
		if ( DEBUG ) {
			warn 'using default READONLY = false';
		}

		$opt{'readonly'} = 0;
	}

	# get our filesystem :)
	if ( exists $opt{'filesystem'} and defined $opt{'filesystem'} ) {
		# validate it
		if ( ! _validate_fs( $opt{'filesystem'} ) ) {
			warn 'invalid filesystem passed to new()';
			return;
		}
	} else {
		if ( DEBUG ) {
			warn 'using default FILESYSTEM = empty';
		}

		$opt{'filesystem'} = {
			File::Spec->rootdir() => {
				'mode'	=> oct( '040755' ),
				'ctime'	=> time(),
			},
		};
	}

	# set the cwd
	if ( exists $opt{'cwd'} and defined $opt{'cwd'} ) {
		# FIXME validate it
	} else {
		if ( DEBUG ) {
			warn 'using default CWD = ' . File::Spec->rootdir();
		}

		$opt{'cwd'} = File::Spec->rootdir();
	}

	# create our instance
	my $self = {
		'fs'		=> $opt{'filesystem'},
		'readonly'	=> $opt{'readonly'},
		'cwd'		=> $opt{'cwd'},
	};
	bless $self, $class;

	return $self;
}

#my %files = (
#	'/' => {
#		mode => oct( '040755' ),
#		ctime => time()-1000,
#	},
#	'/a' => {
#		data => "File 'a'.\n",
#		mode => oct( 100755 ),
#		ctime => time()-2000,
#	},
#	'/b' => {
#		data => "This is file 'b'.\n",
#		mode => oct( 100644 ),
#		ctime => time()-1000,
#	},
#	'/foo' => {
#		mode => oct( '040755' ),
#		ctime => time()-3000,
#	},
#	'/foo/bar' => {
#		data => "APOCAL is the best!\nJust kidding :)\n",
#		mode => oct( 100755 ),
#		ctime => time()-5000,
#	},
#);

# validates a filesystem struct
sub _validate_fs {
	my $fs = shift;

	# FIXME add validation
	return 1;
}

# simple accessor
sub _fs {
	return shift->{'fs'};
}
sub readonly {
	my $self = shift;
	my $ro = shift;
	if ( defined $ro ) {
		$self->{'readonly'} = $ro ? 1 : 0;
	}
	return $self->{'readonly'};
}

sub cwd {
	my( $self, $cwd, $cb ) = @_;

	# sanitize the path
	$cwd = File::Spec->canonpath( $cwd );

	# Get or set?
	if ( ! defined $cwd ) {
		if ( defined $cb ) {
			$cb->( $self->{'cwd'} );
			return;
		} else {
			return $self->{'cwd'};
		}
	}

	# actually change our cwd!
	$self->{'cwd'} = $cwd;
	if ( defined $cb ) {
		$cb->( $cwd );
		return;
	} else {
		return $cwd;
	}
}

sub open {
	my( $self, $path, $flags, $mode, $callback ) = @_;

	# FIXME fix relative path/sanitize path?

	# determine if we should be using callback mode
	if ( ref( $self ) ne __PACKAGE__ ) {
		if ( $self->can( '_open' ) ) {
			my $scalar_ref = $self->_open( $path );
			if ( defined $scalar_ref ) {
				my $fh = IO::Scalar->new( $scalar_ref );
				if ( defined $fh ) {
					$callback->( $fh );
				} else {
					$callback->( -EIO() );
				}
			} else {
				$callback->( -EINVAL() );
			}
		} else {
			$callback->( -ENOSYS() );
		}
		return;
	}

	# make sure we're opening a real file
	if ( exists $self->_fs->{ $path } ) {
		if ( ! S_ISDIR( $self->_fs->{ $path }{'mode'} ) ) {
			# return a $fh object
			my $fh = IO::Scalar->new( \$self->_fs->{ $path }->{'data'} );
			if ( defined $fh ) {
				$callback->( $fh );
			} else {
				$callback->( -EIO() );
			}
		} else {
			# path is a directory!
			$callback->( -EISDIR() );
		}
	} else {
		# path does not exist
		$callback->( -ENOENT() );
	}

	return;
}

sub close {
	my( $self, $fh, $callback ) = @_;

	# cleanly close the FH
	$fh->close;
	$callback->( 0 );

	return;
}

sub read {
	# aio_read $fh,$offset,$length, $data,$dataoffset, $callback->($retval)
	# have to leave @_ alone so caller will get proper $buffer reference :(
	my $self = shift;
	my $fh = shift;

	# seek to $offset
	$fh->seek( $_[0], SEEK_SET );

	# read the data from the fh!
	my $buf = '';
	my $ret = $fh->read( $buf, $_[1], 0 );
	if ( ! defined $ret or $ret == 0 ) {
		$_[4]->( -EIO() );
	} else {
		# stuff the read data into the true buffer, determined by dataoffset
		substr( $_[2], $_[3], $ret, $buf );

		# inform the callback of success
		$_[4]->( $ret );
	}

	return;
}

sub write {
	my( $self, $fh, $offset, $length, $data, $dataoffset, $callback ) = @_;

	# are we readonly?
	if ( $self->readonly ) {
		$callback->( -EROFS() );
	} else {
		# determine if we should be using callback mode
		if ( ref( $self ) ne __PACKAGE__ ) {
			if ( $self->can( '_write' ) ) {
				# FIXME should we also use dataoffset?
				$callback->( $self->_write( $fh, $offset, $length, $data ) );
			} else {
				$callback->( -ENOSYS() );
			}
			return;
		}

		# seek to $offset
		$fh->seek( $offset, SEEK_SET );

		# write the data!
		my $ret = $fh->write( $data, $length, $dataoffset );
		if ( ! $ret ) {
			$callback->( -EIO() );
		} else {
			# return length
			$callback->( length( $data ) - $dataoffset );
		}
	}

	return;
}

sub sendfile {
	my( $self, $out_fh, $in_fh, $in_offset, $length, $callback ) = @_;

	# start by reading $length from $in_fh
	my $buf = '';
	my $ret = $in_fh->read( $buf, $length, $in_offset );
	if ( ! defined $ret or $ret == 0 ) {
		$callback->( -EIO() );
	} else {
		# write it to $out_fh ( at the end )
		$out_fh->seek( 0, SEEK_END );
		$ret = $out_fh->write( $buf, $length );
		if ( $ret ) {
			$callback->( $length );
		} else {
			$callback->( -EIO() );
		}
	}

	return;
}

sub readahead {
	my( $self, $fh, $offset, $length, $callback ) = @_;

	# not implemented, always return success
	$callback->( 0 );
	return;
}

sub stat {
	my( $self, $path, $callback ) = @_;

	# FIXME we don't support array/fh mode because it would require insane amounts of munging the paths
	if ( ref $path ) {
		if ( DEBUG ) {
			warn 'Passing a REF to stat() is not supported!';
		}
		$callback->( -ENOSYS() );
		return;
	}

	# FIXME fix relative path/sanitize path?

	# determine if we should be using callback mode
	if ( ref( $self ) ne __PACKAGE__ ) {
		if ( $self->can( '_stat' ) ) {
			my $ret = $self->_stat( $path );
			if ( defined $ret ) {
				$callback->( $ret );
			} else {
				$callback->( -ENOENT() );
			}
		} else {
			$callback->( -ENOSYS() );
		}
		return;
	}

	# gather the proper information
	if ( exists $self->_fs->{ $path } ) {
		## no critic ( ProhibitAccessOfPrivateData )
		my $info = $self->_fs->{ $path };

		my $size = exists $info->{'data'} ? length( $info->{'data'} ) : 0;
		my $modes = $info->{'mode'};

		my ($dev, $ino, $rdev, $blocks, $gid, $uid, $nlink, $blksize) = ( 0, 0, 0, 1, (split( /\s+/, $) ))[0], $>, 1, 1024 );
		if ( S_ISDIR( $modes ) ) {
			# count the children directories
			$nlink = 2; # start with 2 ( . and .. )

			# FIXME make this portable!
			$nlink += grep { $_ =~ /^$path\/?[^\/]+$/ and S_ISDIR( $self->_fs->{ $_ }{'mode'} ) } ( keys %{ $self->_fs } );
		}

		$gid = $info->{'gid'} if exists $info->{'gid'};
		$uid = $info->{'uid'} if exists $info->{'uid'};
		my ($atime, $ctime, $mtime);
		$atime = $ctime = $mtime = $info->{'ctime'};
		$atime = $info->{'atime'} if exists $info->{'atime'};
		$mtime = $info->{'mtime'} if exists $info->{'mtime'};

		# finally, return the darn data!
		$callback->( [ $dev, $ino, $modes, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks ] );
	} else {
		# path does not exist
		$callback->( -ENOENT() );
	}

	return;
}

sub lstat {
	my( $self, $path, $callback ) = @_;

	# FIXME unimplemented because of complexity
	$callback->( -ENOSYS() );

	return;
}

sub utime {
	my( $self, $path, $atime, $mtime, $callback ) = @_;

	# FIXME we don't support fh mode because it would require insane amounts of munging the paths
	if ( ref $path ) {
		if ( DEBUG ) {
			warn 'Passing a REF to utime() is not supported!';
		}
		$callback->( -ENOSYS() );
		return;
	}

	# are we readonly?
	if ( $self->readonly ) {
		$callback->( -EROFS() );
		return;
	}

	# FIXME fix relative path/sanitize path?

	# determine if we should be using callback mode
	if ( ref( $self ) ne __PACKAGE__ ) {
		if ( $self->can( '_utime' ) ) {
			$callback->( $self->_utime( $path, $atime, $mtime ) );
		} else {
			$callback->( -ENOSYS() );
		}
		return;
	}

	if ( exists $self->_fs->{ $path } ) {
		# okay, update the time
		if ( ! defined $atime ) { $atime = time() }
		if ( ! defined $mtime ) { $mtime = $atime }
		$self->_fs->{ $path }{'atime'} = $atime;
		$self->_fs->{ $path }{'mtime'} = $mtime;

		# successful update of time!
		$callback->( 0 );
	} else {
		# path does not exist
		$callback->( -ENOENT() );
	}

	return;
}

sub chown {
	my( $self, $path, $uid, $gid, $callback ) = @_;

	# FIXME we don't support fh mode because it would require insane amounts of munging the paths
	if ( ref $path ) {
		if ( DEBUG ) {
			warn 'Passing a REF to chown() is not supported!';
		}
		$callback->( -ENOSYS() );
		return;
	}

	# are we readonly?
	if ( $self->readonly ) {
		$callback->( -EROFS() );
		return;
	}

	# FIXME fix relative path/sanitize path?

	# determine if we should be using callback mode
	if ( ref( $self ) ne __PACKAGE__ ) {
		if ( $self->can( '_chown' ) ) {
			$callback->( $self->_chown( $path, $uid, $gid ) );
		} else {
			$callback->( -ENOSYS() );
		}
		return;
	}

	if ( exists $self->_fs->{ $path } ) {
		# okay, update the ownerships!
		if ( defined $uid and $uid > -1 ) {
			$self->_fs->{ $path }{'uid'} = $uid;
		}
		if ( defined $gid and $gid > -1 ) {
			$self->_fs->{ $path }{'gid'} = $gid;
		}

		# successful update of ownership!
		$callback->( 0 );
	} else {
		# path does not exist
		$callback->( -ENOENT() );
	}

	return;
}

sub truncate {
	my( $self, $path, $offset, $callback ) = @_;

	# FIXME we don't support fh mode because it would require insane amounts of munging the paths
	if ( ref $path ) {
		if ( DEBUG ) {
			warn 'Passing a REF to truncate() is not supported!';
		}
		$callback->( -ENOSYS() );
		return;
	}

	# are we readonly?
	if ( $self->readonly ) {
		$callback->( -EROFS() );
		return;
	}

	# FIXME fix relative path/sanitize path?

	# determine if we should be using callback mode
	if ( ref( $self ) ne __PACKAGE__ ) {
		if ( $self->can( '_truncate' ) ) {
			$callback->( $self->_truncate( $path, $offset ) );
		} else {
			$callback->( -ENOSYS() );
		}
		return;
	}

	if ( exists $self->_fs->{ $path } ) {
		if ( ! S_ISDIR( $self->_fs->{ $path }{'mode'} ) ) {
			# valid file, proceed with the truncate!

			# sanity check, offset cannot be bigger than the length of the file!
			if ( $offset > length( $self->_fs->{ $path }{'data'} ) ) {
				$callback->( -EINVAL() );
			} else {
				# did we reach the end of the file?
				if ( $offset != length( $self->_fs->{ $path }{'data'} ) ) {
					# ok, truncate our copy!
					$self->_fs->{ $path }{'data'} = substr( $self->_fs->{ $path }{'data'}, 0, $offset );
				}

				# successfully truncated
				$callback->( 0 );
			}
		} else {
			# path is a directory!
			$callback->( -EISDIR() );
		}
	} else {
		# path does not exist
		$callback->( -ENOENT() );
	}

	return;
}

sub chmod {
	my( $self, $path, $mode, $callback ) = @_;

	# FIXME we don't support fh mode because it would require insane amounts of munging the paths
	if ( ref $path ) {
		if ( DEBUG ) {
			warn 'Passing a REF to chmod() is not supported!';
		}
		$callback->( -ENOSYS() );
		return;
	}

	# are we readonly?
	if ( $self->readonly ) {
		$callback->( -EROFS() );
		return;
	}

	# FIXME fix relative path/sanitize path?

	# determine if we should be using callback mode
	if ( ref( $self ) ne __PACKAGE__ ) {
		if ( $self->can( '_chmod' ) ) {
			$callback->( $self->_chmod( $path, $mode ) );
		} else {
			$callback->( -ENOSYS() );
		}
		return;
	}

	if ( exists $self->_fs->{ $path } ) {
		# okay, update the mode!
		$self->_fs->{ $path }{'mode'} = $mode;

		# successful update of mode!
		$callback->( 0 );
	} else {
		# path does not exist
		$callback->( -ENOENT() );
	}

	return;
}

sub unlink {
	my( $self, $path, $callback ) = @_;

	# are we readonly?
	if ( $self->readonly ) {
		$callback->( -EROFS() );
		return;
	}

	# FIXME fix relative path/sanitize path?

	# determine if we should be using callback mode
	if ( ref( $self ) ne __PACKAGE__ ) {
		if ( $self->can( '_unlink' ) ) {
			$callback->( $self->_unlink( $path ) );
		} else {
			$callback->( -ENOSYS() );
		}
		return;
	}

	if ( exists $self->_fs->{ $path } ) {
		if ( ! S_ISDIR( $self->_fs->{ $path }{'mode'} ) ) {
			# valid file, proceed with the deletion!
			delete $self->_fs->{ $path };

			# successful deletion!
			$callback->( 0 );
		} else {
			# path is a directory!
			$callback->( -EISDIR() );
		}
	} else {
		# path does not exist
		$callback->( -ENOENT() );
	}

	return;
}

sub mknod {
	my( $self, $path, $mode, $dev, $callback ) = @_;

	# are we readonly?
	if ( $self->readonly ) {
		$callback->( -EROFS() );
		return;
	}

	# FIXME fix relative path/sanitize path?

	# we only allow regular files to be created
	if ( $dev == 0 ) {
		# make sure mode is proper
		$mode = $mode | oct( '100000' );
	} else {
		# unsupported mode
		$callback->( -EINVAL() );
		return;
	}

	# determine if we should be using callback mode
	if ( ref( $self ) ne __PACKAGE__ ) {
		if ( $self->can( '_mknod' ) ) {
			$callback->( $self->_mknod( $path, $mode ) );
		} else {
			$callback->( -ENOSYS() );
		}
		return;
	}

	if ( exists $self->_fs->{ $path } or $path eq '.' or $path eq '..' ) {
		# already exists!
		$callback->( -EEXIST() );
	} else {
		# should we add validation to make sure all parents already exist
		# seems like touch() and friends check themselves, so we don't have to do it...

		$self->_fs->{ $path } = {
			mode => $mode,
			ctime => time(),
			data => "",
		};

		# successful creation!
		$callback->( 0 );
	}

	return;
}

sub link {
	my( $self, $srcpath, $dstpath, $callback ) = @_;

	# FIXME unimplemented because of complexity
	$callback->( -ENOSYS() );

	return;
}

sub symlink {
	my( $self, $srcpath, $dstpath, $callback ) = @_;

	# FIXME unimplemented because of complexity
	$callback->( -ENOSYS() );

	return;
}

sub readlink {
	my( $self, $path, $callback ) = @_;

	# FIXME unimplemented because of complexity
	$callback->( -ENOSYS() );

	return;
}

sub rename {
	my( $self, $srcpath, $dstpath, $callback ) = @_;

	# are we readonly?
	if ( $self->readonly ) {
		$callback->( -EROFS() );
		return;
	}

	# FIXME fix relative path/sanitize path?

	# determine if we should be using callback mode
	if ( ref( $self ) ne __PACKAGE__ ) {
		if ( $self->can( '_rename' ) ) {
			$callback->( $self->_rename( $srcpath, $dstpath ) );
		} else {
			$callback->( -ENOSYS() );
		}
		return;
	}

	if ( exists $self->_fs->{ $srcpath } ) {
		if ( ! exists $self->_fs->{ $dstpath } ) {
			# should we add validation to make sure all parents already exist
			# seems like mv() and friends check themselves, so we don't have to do it...

			# proceed with the rename!
			$self->_fs->{ $dstpath } = delete $self->_fs->{ $srcpath };

			$callback->( 0 );
		} else {
			# destination already exists!
			$callback->( -EEXIST() );
		}
	} else {
		# path does not exist
		$callback->( -ENOENT() );
	}

	return;
}

sub mkdir {
	my( $self, $path, $mode, $callback ) = @_;

	# are we readonly?
	if ( $self->readonly ) {
		$callback->( -EROFS() );
		return;
	}

	# FIXME fix relative path/sanitize path?

	# make sure mode is proper
	$mode = $mode | oct( '040000' );

	# determine if we should be using callback mode
	if ( ref( $self ) ne __PACKAGE__ ) {
		if ( $self->can( '_mkdir' ) ) {
			$callback->( $self->_mkdir( $path, $mode ) );
		} else {
			$callback->( -ENOSYS() );
		}
		return;
	}

	if ( exists $self->_fs->{ $path } ) {
		# already exists!
		$callback->( -EEXIST() );
	} else {
		# should we add validation to make sure all parents already exist
		# seems like mkdir() and friends check themselves, so we don't have to do it...

		# create the directory!
		$self->_fs->{ $path } = {
			mode => $mode,
			ctime => time(),
		};

		# successful creation!
		$callback->( 0 );
	}

	return;
}

sub rmdir {
	my( $self, $path, $callback ) = @_;

	# are we readonly?
	if ( $self->readonly ) {
		$callback->( -EROFS() );
		return;
	}

	# FIXME fix relative path/sanitize path?

	# determine if we should be using callback mode
	if ( ref( $self ) ne __PACKAGE__ ) {
		if ( $self->can( '_rmdir' ) ) {
			$callback->( $self->_rmdir( $path ) );
		} else {
			$callback->( -ENOSYS() );
		}
		return;
	}

	if ( exists $self->_fs->{ $path } ) {
		if ( S_ISDIR( $self->_fs->{ $path }{'mode'} ) ) {
			# valid directory, does this directory have any children ( files, subdirs ) ??
			my $children = grep { $_ =~ /^$path/ } ( keys %{ $self->_fs } );
			if ( $children == 1 ) {
				delete $self->_fs->{ $path };

				# successful deletion!
				$callback->( 0 );
			} else {
				# need to delete children first!
				$callback->( -ENOTEMPTY() );
			}
		} else {
			# path is not a directory!
			$callback->( -ENOTDIR() );
		}
	} else {
		# path does not exist
		$callback->( -ENOENT() );
	}

	return;
}

sub readdir {
	my( $self, $path, $callback ) = @_;

	# FIXME fix relative path/sanitize path?

	# determine if we should be using callback mode
	if ( ref( $self ) ne __PACKAGE__ ) {
		if ( $self->can( '_readdir' ) ) {
			$callback->( $self->_readdir( $path ) );
		} else {
			$callback->( -ENOSYS() );
		}
		return;
	}

	if ( exists $self->_fs->{ $path } ) {
		if ( S_ISDIR( $self->_fs->{ $path }{'mode'} ) ) {
			# construct all the data in this directory
			# FIXME make this portable!
			my @list = grep { $_ =~ /^$path\/?[^\/]+$/ } ( keys %{ $self->_fs } );
			s/^$path\/?// for @list;

			# no need to add "." and ".."

			# return the list!
			$callback->( \@list );
		} else {
			# path is not a directory!
			$callback->( -ENOTDIR() );
		}
	} else {
		# path does not exist!
		$callback->( -ENOENT() );
	}

	return;
}

sub load {
	# have to leave @_ alone so caller will get proper $data reference :(
	my $self = shift;
	my $path = shift;

	# FIXME fix relative path/sanitize path?

	# determine if we should be using callback mode
	if ( ref( $self ) ne __PACKAGE__ ) {
		if ( $self->can( '_load' ) ) {
			$_[1]->( $self->_load( $path, $_[0] ) );
		} else {
			$_[1]->( -ENOSYS() );
		}
		return;
	}

	if ( exists $self->_fs->{ $path } ) {
		if ( ! S_ISDIR( $self->_fs->{ $path }{'mode'} ) ) {
			# simply read it all into the buf
			$_[0] = $self->_fs->{ $path }{'data'};

			# successful load!
			$_[1]->( length( $self->_fs->{ $path }{'data'} ) );
		} else {
			# path is a directory!
			$_[1]->( -EISDIR() );
		}
	} else {
		# path does not exist
		$_[1]->( -ENOENT() );
	}

	return;
}

sub copy {
	my( $self, $srcpath, $dstpath, $callback ) = @_;

	# are we readonly?
	if ( $self->readonly ) {
		$callback->( -EROFS() );
		return;
	}

	# FIXME fix relative path/sanitize path?

	# determine if we should be using callback mode
	if ( ref( $self ) ne __PACKAGE__ ) {
		if ( $self->can( '_copy' ) ) {
			$callback->( $self->_copy( $srcpath, $dstpath ) );
		} else {
			$callback->( -ENOSYS() );
		}
		return;
	}

	if ( exists $self->_fs->{ $srcpath } ) {
		if ( ! exists $self->_fs->{ $dstpath } ) {
			# should we add validation to make sure all parents already exist
			# seems like cp() and friends check themselves, so we don't have to do it...

			# proceed with the copy!
			$self->_fs->{ $dstpath } = { %{ $self->_fs->{ $srcpath } } };

			$callback->( 0 );
		} else {
			# destination already exists!
			$callback->( -EEXIST() );
		}
	} else {
		# path does not exist
		$callback->( -ENOENT() );
	}

	return;
}

sub move {
	my( $self, $srcpath, $dstpath, $callback ) = @_;

	# are we readonly?
	if ( $self->readonly ) {
		$callback->( -EROFS() );
		return;
	}

	# determine if we should be using callback mode
	if ( ref( $self ) ne __PACKAGE__ ) {
		if ( $self->can( '_move' ) ) {
			$callback->( $self->_move( $srcpath, $dstpath ) );
		} else {
			$callback->( -ENOSYS() );
		}
		return;
	}

	# to us, move is equivalent to rename
	$self->rename( $srcpath, $dstpath, $callback );

	return;
}

sub scandir {
	my( $self, $path, $maxreq, $callback ) = @_;

	# FIXME fix relative path/sanitize path?

	# determine if we should be using callback mode
	if ( ref( $self ) ne __PACKAGE__ ) {
		if ( $self->can( '_scandir' ) ) {
			$callback->( $self->_scandir( $path ) );
		} else {
			$callback->( -ENOSYS() );
		}
		return;
	}

	if ( exists $self->_fs->{ $path } ) {
		if ( S_ISDIR( $self->_fs->{ $path }{'mode'} ) ) {
			# construct all the data in this directory
			# FIXME make this portable!
			my @files = grep { $_ =~ /^$path\/?[^\/]+$/ and ! S_ISDIR( $self->_fs->{ $_ }{'mode'} ) } ( keys %{ $self->_fs } );
			s/^$path\/?// for @files;

			my @dirs = grep { $_ =~ /^$path\/?[^\/]+$/ and S_ISDIR($self->_fs->{ $_ }{'mode'} ) } ( keys %{ $self->_fs } );
			s/^$path\/?// for @dirs;

			# no need to add "." and ".."

			# return the list!
			$callback->( \@files, \@dirs );
		} else {
			# path is not a directory!
			$callback->( -ENOTDIR() );
		}
	} else {
		# path does not exist!
		$callback->( -ENOENT() );
	}

	return;
}

sub rmtree {
	my( $self, $path, $callback ) = @_;

	# are we readonly?
	if ( $self->readonly ) {
		$callback->( -EROFS() );
		return;
	}

	# FIXME fix relative path/sanitize path?

	# determine if we should be using callback mode
	if ( ref( $self ) ne __PACKAGE__ ) {
		if ( $self->can( '_rmtree' ) ) {
			$callback->( $self->_rmtree( $path ) );
		} else {
			$callback->( -ENOSYS() );
		}
		return;
	}

	if ( exists $self->_fs->{ $path } ) {
		if ( S_ISDIR( $self->_fs->{ $path }{'mode'} ) ) {
			# delete all stuff under this path
			# FIXME make this portable!
			my @entries = grep { $_ =~ /^$path\/?.+$/ } ( keys %{ $self->_fs } );
			foreach my $e ( @entries ) {
				delete $self->_fs->{ $e };
			}

			# return success
			$callback->( 0 );
		} else {
			# path is not a directory!
			$callback->( -ENOTDIR() );
		}
	} else {
		# path does not exist
		$callback->( -ENOENT() );
	}

	return;
}

sub fsync {
	my( $self, $fh, $callback ) = @_;

	# not implemented, always return success
	$callback->( 0 );

	return;
}

sub fdatasync {
	my( $self, $fh, $callback ) = @_;

	# not implemented, always return success
	$callback->( 0 );

	return;
}

1;
__END__

=for stopwords API ENOSYS Kwalitee callbacks com cwd diff github linux readonly stat vfs xantus ramfs AnnoCPAN CPAN CPANTS RT TODO

=head1 NAME

Filesys::Virtual::Async::inMemory - Mount filesystems that reside in memory ( sort of ramfs )

=head1 SYNOPSIS

	#!/usr/bin/perl
	use strict; use warnings;
	use Fcntl qw( :DEFAULT :mode );	# S_IFREG S_IFDIR, O_SYNC O_LARGEFILE etc

	# uncomment this to enable debugging
	#sub Filesys::Virtual::Async::inMemory::DEBUG { 1 }

	use Filesys::Virtual::Async::inMemory;

	# create the filesystem
	my $vfs = Filesys::Virtual::Async::inMemory->new(
		'filesystem'	=> {
			'/'	=> {
				mode => oct( '040755' ),
				ctime => time(),
			},
		},
	);

	# use $vfs as you wish!
	$vfs->readdir( '/', sub {	# should print out nothing
		my $data = shift;
		if ( defined $data ) {
			foreach my $e ( @$data ) {
				print "entry in / -> $e\n";
			}
			print "end of listing for /\n";
		} else {
			print "error reading /\n";
		}
		do_file_io();
	} );

	my $fh;
	sub do_file_io {
		$vfs->mknod( '/bar', oct( '100644' ), 0, \&did_mknod );
	}
	sub did_mknod {
		if ( $_[0] == 0 ) {
			# write to it!
			$vfs->open( '/bar', O_RDWR, 0, \&did_open );
		} else {
			print "error mknod /bar\n";
		}
	}
	sub did_open {
		$fh = shift;
		if ( defined $fh ) {
			my $buf = "foobar";
			$vfs->write( $fh, 0, length( $buf ), $buf, 0, \&did_write );
		} else {
			print "error opening /bar\n";
		}
	}
	sub did_write {
		my $wrote = shift;
		if ( $wrote ) {
			print "successfully wrote to /bar\n";
			$vfs->close( $fh, \&did_close );
		} else {
			print "error writing to /bar\n";
		}
	}
	sub did_close {
		my $status = shift;
		if ( $status == 0 ) {
			print "successfuly closed fh\n";
		} else {
			print "error in closing fh\n";
		}
	}


=head1 ABSTRACT

Using this module will enable you to have "ramfs" filesystems in the L<Filesys::Virtual::Async> API.

=head1 DESCRIPTION

This module lets you run the L<Filesys::Virtual::Async> API entirely in memory. Nothing special here, really :)

This module makes extensive use of the functions in L<File::Spec> to be portable, so it might trip you up if
you are developing on a linux box and trying to play with '/foo' on a win32 box :)

=head2 Initializing the vfs

This constructor accepts either a hashref or a hash, valid options are:

=head3 filesystem

This sets the "filesystem" that we will have in memory. It needs to be a particular structure!

If this argument is missing, we will create an empty filesystem.

=head3 readonly

This enables readonly mode, which will prohibit any changes to the filesystem.

The default is: false

=head3 cwd

This sets the "current working directory" in the filesystem.

The default is: File::Spec->rootdir()

=head2 METHODS

=head3 readonly

Enables/disables readonly mode. This is also an accessor.

=head2 Special Cases

This module does a good job of covering the entire ::Async API, but there are some areas that needs mentioning.

=head3 root

Unimplemented, No sense in changing the root during run-time...

=head3 stat

Array mode not supported because it would require extra munging on my part to get the paths right.

=head3 link/symlink/lstat

Links are not supported at this time because of the complexity involved.

=head3 readahead/fsync/fdatasync

Always returns success ( 0 ), because they are useless to us

=head2 Subclassing this module

If you want to subclass this module, please read on! The primary reason for subclassing is so you have true "callbacks"
whenever the API is called, instead of providing a static filesystem structure. This module tries to do it's best
to reduce the pain, but you would need to be aware of some things.

The way this module implements subclassing is to call a private method whenever it detects a subclass using this
module as a superclass. Please don't override the ::Async API! What you need to do is define your own _method subs
for the ones you want to override. All other methods that aren't defined will return ENOSYS to the ::Async API.

Available methods to implement: _rmtree, _scandir, _move, _copy, _load, _readdir, _rmdir, _mkdir, _rename, _mknod,
_unlink, _chmod, _truncate, _chown, _utime, _stat, _write, _open.

Again, please look at the source for this module to see how it interacts with the subclass. Some of the methods have
been "simplified" to reduce the pain of managing the data. Be sure to let this module create the object, because
we need the "readonly" attribute to be present in the hash! If "readonly" is set, this module will take over the
logic for certain methods and not call your method if there's a readonly violation ( write(), for example ).

=head2 Debugging

You can enable debug mode which prints out some information ( and especially error messages ) by doing this:

	sub Filesys::Virtual::Async::inMemory::DEBUG () { 1 }
	use Filesys::Virtual::Async::inMemory;

=head2 TODO

=over 4

=item * automatically overriding CORE::* methods

	#poe@magnet

	<buu> Apocalypse: Hey, while you're at it, can you make it so all file access operators in perl operate on virtual directories?
	<Apocalypse> buu: hm you mean overriding readdir(), stat()?
	<buu> Yes.
	<Apocalypse> as of now you would have to explicitly use the filesys::virtual::async::inmemory object and do operations on it -> $fsv->readdir(), $fsv->open(), etc
	<buu> But I don't want to!
	<buu> =]
	<Apocalypse> but that would be a fun side project to try and figure out how to hijack CORE:: stuff
	<buu> Yes!
	<Apocalypse> hmm you could locally scope the hijack, pass a $fsv object to the module init, and have it transparently replace all file operations in the scope with $fsv->method calls
	<Apocalypse> why would you want it? pure laziness? haha
	<buu> Apocalypse: For buubot..
	<Apocalypse> mmm for now you can just use fsv::inmemory until somebody with enough wizardry does the overrides :)
	<Apocalypse> I'll file that away in my TODO and see if I will return to it someday hah
	<buu> Exccelent.

=back

=head1 SEE ALSO

L<Filesys::Virtual::Async>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Filesys::Virtual::Async::inMemory

=head2 Websites

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Filesys-Virtual-Async-inMemory>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Filesys-Virtual-Async-inMemory>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Filesys-Virtual-Async-inMemory>

=item * CPAN Forum

L<http://cpanforum.com/dist/Filesys-Virtual-Async-inMemory>

=item * RT: CPAN's Request Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Filesys-Virtual-Async-inMemory>

=item * CPANTS Kwalitee

L<http://cpants.perl.org/dist/overview/Filesys-Virtual-Async-inMemory>

=item * CPAN Testers Results

L<http://cpantesters.org/distro/F/Filesys-Virtual-Async-inMemory.html>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Filesys-Virtual-Async-inMemory>

=item * Git Source Code Repository

This code is currently hosted on github.com under the account "apocalypse". Please feel free to browse it
and pull from it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/apocalypse/perl-filesys-virtual-async-inmemory>

=back

=head2 Bugs

Please report any bugs or feature requests to C<bug-filesys-virtual-async-inmemory at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Filesys-Virtual-Async-inMemory>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to xantus who got me motivated to write this :)

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
