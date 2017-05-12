# Declare our package
package Filesys::Virtual::Async::Dispatcher;
use strict; use warnings;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.02';

# set our superclass
use base 'Filesys::Virtual::Async';

# get some handy stuff
use File::Spec;

# get the refaddr of our FHs
use Scalar::Util qw( refaddr openhandle );

# get some system constants
use Errno qw( :POSIX );			# ENOENT EISDIR etc
use Fcntl qw( :DEFAULT :mode :seek );	# S_IFREG S_IFDIR, O_SYNC O_LARGEFILE etc

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
			die __PACKAGE__ . ' requires an even number of options passed to new()';
		}

		%opt = @_;
	}

	# lowercase keys
	%opt = map { lc($_) => $opt{$_} } keys %opt;

	# set the rootfs
	if ( ! exists $opt{'rootfs'} or ! defined $opt{'rootfs'} or ! ref $opt{'rootfs'} ) {
		die __PACKAGE__ . ' needs rootfs defined to bootstrap';
	} else {
		# make sure it's the proper object
		if ( ! $opt{'rootfs'}->isa( 'Filesys::Virtual::Async' ) ) {
			die 'rootfs is not a valid ::Async subclass';
		}
	}

	# create our instance
	my $self = {
		'cwd'		=> $opt{'rootfs'}->cwd || File::Spec->rootdir(),
		'mounts'	=> {},
		'mountstree'	=> {},
		'fhmap'		=> {},
	};
	bless $self, $class;

	# initialize the first mount
	$self->mount( File::Spec->rootdir(), $opt{'rootfs'} );

	return $self;
}

sub mount {
	my( $self, $path, $vfs ) = @_;

	# sanity
	if ( ! defined $path ) {
		if ( DEBUG ) {
			warn 'invalid path';
		}
		return 0;
	} else {
		# sanitize the path
		$path = File::Spec->canonpath( $path );
	}

	# make sure it's a valid subclass
	if ( ! defined $vfs or ! ref $vfs or ! $vfs->isa( 'Filesys::Virtual::Async' ) ) {
		if ( DEBUG ) {
			warn 'vfs is not a valid ::Async subclass';
		}
		return 0;
	}

	# FIXME Does the directory exist?
	# this is insane... we need a callback to stat() and see if it exists!
	# for now, we blindly mount, ha!

	# Is that path taken?
	if ( exists $self->{'mounts'}->{ $path } ) {
		if ( DEBUG ) {
			warn 'unable to mount over another mount';
		}
		return 0;
	}

	# Split up the path
	my @dirs;
	if ( $path eq File::Spec->rootdir() ) {
		push( @dirs, File::Spec->rootdir() );
	} else {
		@dirs = File::Spec->splitdir( $path );
		if ( @dirs ) {
			$dirs[0] = File::Spec->rootdir();
		} else {
			if ( DEBUG ) {
				warn 'path is not a valid directory name';
			}
			return 0;
		}
	}

	# store it!
	if ( DEBUG ) {
		warn "mounting '$path' with $vfs";
	}
	$self->{'mounts'}->{ $path } = $vfs;

	# build the tree
	my $curpos = $self->{'mountstree'};
	foreach my $dir ( @dirs ) {
		## no critic ( ProhibitAccessOfPrivateData )
		$curpos->{ $dir } = {} if not exists $curpos->{ $dir };
		$curpos = $curpos->{ $dir };
	}

	return 1;
}

sub umount {
	my( $self, $path ) = @_;

	# sanity
	if ( ! defined $path ) {
		if ( DEBUG ) {
			warn 'invalid path';
		}
		return 0;
	} else {
		# sanitize the path
		$path = File::Spec->canonpath( $path );
	}

	# unable to umount the rootfs, hah!
	if ( $path eq File::Spec->rootdir() ) {
		if ( DEBUG ) {
			warn 'unable to umount the rootfs';
		}
		return 0;
	}

	# is the path mounted?
	if ( ! exists $self->{'mounts'}->{ $path } ) {
		if ( DEBUG ) {
			warn "directory '$path' is not mounted";
		}
		return 0;
	}

	# are there any mounts under this one?
	my @matches = grep { $_ =~ /^$path/ } ( keys %{ $self->{'mounts'} } );
	if ( @matches > 1 ) {
		if ( DEBUG ) {
			warn "unable to umount '$path' as there are more mounts inside it";
		}
		return 0;
	}

	if ( DEBUG ) {
		warn "umounting '$path'";
	}

	# unmount it!
	delete $self->{'mounts'}->{ $path };

	# clean up the tree
	my @dirs = File::Spec->splitdir( $path );
	shift( @dirs );	# get rid of the root entry which is always '' for me
	my $curpath = File::Spec->rootdir();
	my $curpos = $self->{'mountstree'}->{ $curpath };
	foreach my $dir ( @dirs ) {
		$curpath = File::Spec->catdir( $curpath, $dir );
		if ( ! exists $self->{'mounts'}->{ $curpath } ) {
			# yay, reached end of tree
			delete $curpos->{ $dir };	## no critic ( ProhibitAccessOfPrivateData )
			last;
		} else {
			$curpos = $curpos->{ $dir };	## no critic ( ProhibitAccessOfPrivateData )
		}
	}

	return 1;
}

sub _findmount {
	my( $self, $path ) = @_;

	# get an absolute path
	$path = File::Spec->rel2abs( $path, $self->{'cwd'} );

	# traverse the tree, searching for the "deepest" hash we can find
	my @dirs = File::Spec->splitdir( $path );
	shift( @dirs );	# get rid of the root entry which is always '' for me
	my $curpath = File::Spec->rootdir();
	my $curpos = $self->{'mountstree'}->{ $curpath };
	foreach my $dir ( @dirs ) {
		## no critic ( ProhibitAccessOfPrivateData )
		if ( exists $curpos->{ $dir } ) {
			$curpath = File::Spec->catdir( $curpath, $dir );

			# is it the end?
			if ( ! defined $curpos->{ $dir } ) {
				# found our match!
				last;
			} else {
				# continue traversing
				$curpos = $curpos->{ $dir };
			}
		} else {
			# found our match!
			last;
		}
	}

	# grab the mount object
	if ( ! exists $self->{'mounts'}->{ $curpath } ) {
		die "internal inconsistency - unable to find mount path($path) curpath($curpath)";
	}

	# figure out the relative path
	my $relpath = File::Spec->catdir( File::Spec->rootdir(), File::Spec->abs2rel( $path, $curpath ) );

	# all done!
	return $self->{'mounts'}->{ $curpath }, $relpath;
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

	# Is it the same cwd as we have?
	if ( $cwd eq $self->{'cwd'} ) {
		if ( defined $cb ) {
			$cb->( $cwd );
			return;
		} else {
			return $cwd;
		}
	}

	# actually change our cwd!
	$self->{'cwd'} = $cwd;
	my( $mount, $where ) = $self->_findmount( $cwd );
	if ( defined $cb ) {
		$mount->cwd( $where, $cb );
		return;
	} else {
		return $mount->cwd( $where );
	}
}

sub root {
	# we cannot sanely do this because we have no idea which mount to apply it to...
	if ( DEBUG ) {
		warn 'Setting root on the dispatcher has no meaning, please do it directly on the mount!';
	}
	return;
}

sub _resolve_fh {
	my $self = shift;
	my $fh = shift;
	my $ret = undef;
	if ( openhandle( $fh ) ) {
		$ret = refaddr( $fh );
		if ( ! defined $ret ) {
			# try direct stringy eval
			$ret = "$fh";
		}
	}

	return $ret;
}

sub dirlist {
	my ( $self, $path, $withstat, $callback ) = @_;

	my( $mount, $where ) = $self->_findmount( $path );
	$mount->dirlist( $where, $withstat, $callback );

	return;
}

sub open {
	my( $self, $path, $flags, $mode, $callback ) = @_;

	# construct our custom callback
	my $cb = sub {
		my $fh = shift;
		if ( defined $fh ) {
			my $mapping = $self->_resolve_fh( $fh );
			if ( defined $mapping ) {
				if ( exists $self->{'fhmap'}->{ $mapping } ) {
					die "internal inconsistency - fh already exists in fhmap!";
				}

				# FIXME does $path need to be relative or absolute?
				$self->{'fhmap'}->{ $mapping } = $path;
				$callback->( $fh );
			} else {
				# must be an error code
				$callback->( $fh );
			}
		} else {
			$callback->( -EIO() );
		}
	};

	my( $mount, $where ) = $self->_findmount( $path );
	$mount->open( $where, $flags, $mode, $cb );

	return;
}

sub close {
	my( $self, $fh, $callback ) = @_;

	# get the proper mount
	my $mapping = $self->_resolve_fh( $fh );
	if ( defined $mapping ) {
		if ( exists $self->{'fhmap'}->{ $mapping } ) {
			my( $mount, undef ) = $self->_findmount( delete $self->{'fhmap'}->{ $mapping } );

			$mount->close( $fh, $callback );
		} else {
			die "internal inconsistency - unknown fh: $fh";
		}
	} else {
		die "internal inconsistency - unknown fh: $fh";
	}

	return;
}

sub read {
	# have to leave @_ alone so aio_read will get proper $buffer reference :(
	my $self = shift;
	my $fh = shift;

	# get the proper mount
	my $mapping = $self->_resolve_fh( $fh );
	if ( defined $mapping ) {
		if ( exists $self->{'fhmap'}->{ $mapping } ) {
			my( $mount, undef ) = $self->_findmount( $self->{'fhmap'}->{ $mapping } );

			$mount->read( $fh, $_[0], $_[1], $_[2], $_[3], $_[4] );
		} else {
			die "internal inconsistency - unknown fh: $fh";
		}
	} else {
		die "internal inconsistency - unknown fh: $fh";
	}

	return;
}

sub write {
	# have to leave @_ alone so aio_read will get proper $buffer reference :(
	my $self = shift;
	my $fh = shift;

	# get the proper mount
	my $mapping = $self->_resolve_fh( $fh );
	if ( defined $mapping ) {
		if ( exists $self->{'fhmap'}->{ $mapping } ) {
			my( $mount, undef ) = $self->_findmount( $self->{'fhmap'}->{ $mapping } );

			$mount->write( $fh, $_[0], $_[1], $_[2], $_[3], $_[4] );
		} else {
			die "internal inconsistency - unknown fh: $fh";
		}
	} else {
		die "internal inconsistency - unknown fh: $fh";
	}

	return;
}

sub sendfile {
	my( $self, $out_fh, $in_fh, $in_offset, $length, $callback ) = @_;

	# FIXME make sure both fh's belong to the same mount?
	# also, which fh should we "select" from to determine mountpoint? I'm defaulting to $in_fh here...

	# get the proper mount
	my $mapping = $self->_resolve_fh( $in_fh );
	if ( defined $mapping ) {
		if ( exists $self->{'fhmap'}->{ $mapping } ) {
			my( $mount, undef ) = $self->_findmount( $self->{'fhmap'}->{ $mapping } );

			$mount->sendfile( $out_fh, $in_fh, $in_offset, $length, $callback );
		} else {
			die "internal inconsistency - unknown fh: $in_fh";
		}
	} else {
		die "internal inconsistency - unknown fh: $in_fh";
	}

	return;
}

sub readahead {
	my( $self, $fh, $offset, $length, $callback ) = @_;

	# get the proper mount
	my $mapping = $self->_resolve_fh( $fh );
	if ( defined $mapping ) {
		if ( exists $self->{'fhmap'}->{ $mapping } ) {
			my( $mount, undef ) = $self->_findmount( $self->{'fhmap'}->{ $mapping } );

			$mount->readahead( $fh, $offset, $length, $callback );
		} else {
			die "internal inconsistency - unknown fh: $fh";
		}
	} else {
		die "internal inconsistency - unknown fh: $fh";
	}

	return;
}

sub stat {
	my( $self, $fh_or_path, $callback ) = @_;

	# FIXME we don't support array mode because it would require insane amounts of munging the paths
	if ( ref $fh_or_path and ref( $fh_or_path ) eq 'ARRAY' ) {
		if ( DEBUG ) {
			warn 'Passing an ARRAY to stat() is not supported by the Dispatcher!';
		}
		$callback->( undef );
		return;
	}

	# is it a fh or path?
	if ( ref $fh_or_path ) {
		# get the proper mount
		my $mapping = $self->_resolve_fh( $fh_or_path );
		if ( defined $mapping ) {
			if ( exists $self->{'fhmap'}->{ $mapping } ) {
				my( $mount, undef ) = $self->_findmount( $self->{'fhmap'}->{ $mapping } );
				$mount->stat( $fh_or_path, $callback );
			} else {
				die "internal inconsistency - unknown fh: $fh_or_path";
			}
		} else {
			die "internal inconsistency - unknown fh: $fh_or_path";
		}
	} else {
		my( $mount, $where ) = $self->_findmount( $fh_or_path );
		$mount->stat( $where, $callback );
	}

	return;
}

sub lstat {
	my( $self, $fh_or_path, $callback ) = @_;

	# FIXME we don't support array mode because it would require insane amounts of munging the paths
	if ( ref $fh_or_path and ref( $fh_or_path ) eq 'ARRAY' ) {
		if ( DEBUG ) {
			warn 'Passing an ARRAY to lstat() is not supported by the Dispatcher!';
		}
		$callback->( undef );
		return;
	}

	# is it a fh or path?
	if ( ref $fh_or_path ) {
		# get the proper mount
		my $mapping = $self->_resolve_fh( $fh_or_path );
		if ( defined $mapping ) {
			if ( exists $self->{'fhmap'}->{ $mapping } ) {
				my( $mount, undef ) = $self->_findmount( $self->{'fhmap'}->{ $mapping } );
				$mount->lstat( $fh_or_path, $callback );
			} else {
				die "internal inconsistency - unknown fh: $fh_or_path";
			}
		} else {
			die "internal inconsistency - unknown fh: $fh_or_path";
		}
	} else {
		my( $mount, $where ) = $self->_findmount( $fh_or_path );
		$mount->lstat( $where, $callback );
	}

	return;
}

sub utime {
	my( $self, $fh_or_path, $atime, $mtime, $callback ) = @_;

	# is it a fh or path?
	if ( ref $fh_or_path ) {
		# get the proper mount
		my $mapping = $self->_resolve_fh( $fh_or_path );
		if ( defined $mapping ) {
			if ( exists $self->{'fhmap'}->{ $mapping } ) {
				my( $mount, undef ) = $self->_findmount( $self->{'fhmap'}->{ $mapping } );
				$mount->utime( $fh_or_path, $atime, $mtime, $callback );
			} else {
				die "internal inconsistency - unknown fh: $fh_or_path";
			}
		} else {
			die "internal inconsistency - unknown fh: $fh_or_path";
		}
	} else {
		my( $mount, $where ) = $self->_findmount( $fh_or_path );
		$mount->utime( $where, $atime, $mtime, $callback );
	}

	return;
}

sub chown {
	my( $self, $fh_or_path, $uid, $gid, $callback ) = @_;

	# is it a fh or path?
	if ( ref $fh_or_path ) {
		# get the proper mount
		my $mapping = $self->_resolve_fh( $fh_or_path );
		if ( defined $mapping ) {
			if ( exists $self->{'fhmap'}->{ $mapping } ) {
				my( $mount, undef ) = $self->_findmount( $self->{'fhmap'}->{ $mapping } );
				$mount->chown( $fh_or_path, $uid, $gid, $callback );
			} else {
				die "internal inconsistency - unknown fh: $fh_or_path";
			}
		} else {
			die "internal inconsistency - unknown fh: $fh_or_path";
		}
	} else {
		my( $mount, $where ) = $self->_findmount( $fh_or_path );
		$mount->chown( $where, $uid, $gid, $callback );
	}

	return;
}

sub truncate {
	my( $self, $fh_or_path, $offset, $callback ) = @_;

	# is it a fh or path?
	if ( ref $fh_or_path ) {
		# get the proper mount
		my $mapping = $self->_resolve_fh( $fh_or_path );
		if ( defined $mapping ) {
			if ( exists $self->{'fhmap'}->{ $mapping } ) {
				my( $mount, undef ) = $self->_findmount( $self->{'fhmap'}->{ $mapping } );
				$mount->truncate( $fh_or_path, $offset, $callback );
			} else {
				die "internal inconsistency - unknown fh: $fh_or_path";
			}
		} else {
			die "internal inconsistency - unknown fh: $fh_or_path";
		}
	} else {
		my( $mount, $where ) = $self->_findmount( $fh_or_path );
		$mount->truncate( $where, $offset, $callback );
	}

	return;
}

sub chmod {
	my( $self, $fh_or_path, $mode, $callback ) = @_;

	# is it a fh or path?
	if ( ref $fh_or_path ) {
		# get the proper mount
		my $mapping = $self->_resolve_fh( $fh_or_path );
		if ( defined $mapping ) {
			if ( exists $self->{'fhmap'}->{ $mapping } ) {
				my( $mount, undef ) = $self->_findmount( $self->{'fhmap'}->{ $mapping } );
				$mount->chmod( $fh_or_path, $mode, $callback );
			} else {
				die "internal inconsistency - unknown fh: $fh_or_path";
			}
		} else {
			die "internal inconsistency - unknown fh: $fh_or_path";
		}
	} else {
		my( $mount, $where ) = $self->_findmount( $fh_or_path );
		$mount->chmod( $where, $mode, $callback );
	}

	return;
}

sub unlink {
	my( $self, $path, $callback ) = @_;

	my( $mount, $where ) = $self->_findmount( $path );
	$mount->unlink( $where, $callback );

	return;
}

sub mknod {
	my( $self, $path, $mode, $dev, $callback ) = @_;

	my( $mount, $where ) = $self->_findmount( $path );
	$mount->mknod( $where, $mode, $dev, $callback );

	return;
}

sub link {
	my( $self, $srcpath, $dstpath, $callback ) = @_;

	# we disallow links across mounts, because it's impossible to get arbitrary mounts to cooperate :(
	my( $mount, $where ) = $self->_findmount( $srcpath );
	my( $mount2, $where2 ) = $self->_findmount( $dstpath );
	if ( $mount != $mount2 ) {
		if ( DEBUG ) {
			warn 'linking across mounts is not supported by the Dispatcher!';
		}
		$callback->( -1 );	# FIXME what's the proper failure code?
		return;
	}

	$mount->link( $where, $where2, $callback );

	return;
}

sub symlink {
	my( $self, $srcpath, $dstpath, $callback ) = @_;

	# we disallow links across mounts, because it's impossible to get arbitrary mounts to cooperate :(
	my( $mount, $where ) = $self->_findmount( $srcpath );
	my( $mount2, $where2 ) = $self->_findmount( $dstpath );
	if ( $mount != $mount2 ) {
		if ( DEBUG ) {
			warn 'linking across mounts is not supported by the Dispatcher!';
		}
		$callback->( -1 );	# FIXME what's the proper failure code?
		return;
	}

	$mount->symlink( $where, $where2, $callback );

	return;
}

sub readlink {
	my( $self, $path, $callback ) = @_;

	my( $mount, $where ) = $self->_findmount( $path );
	$mount->readlink( $where, $callback );

	return;
}

sub rename {
	my( $self, $srcpath, $dstpath, $callback ) = @_;

	# FIXME we theoretically could rename across mounts by implementing it ourself, but I'm lazy now :)
	my( $mount, $where ) = $self->_findmount( $srcpath );
	my( $mount2, $where2 ) = $self->_findmount( $dstpath );
	if ( $mount != $mount2 ) {
		if ( DEBUG ) {
			warn 'renaming across mounts is not supported by the Dispatcher!';
		}
		$callback->( -1 );	# FIXME what's the proper failure code?
		return;
	}

	$mount->rename( $where, $where2, $callback );

	return;
}

sub mkdir {
	my( $self, $path, $mode, $callback ) = @_;

	my( $mount, $where ) = $self->_findmount( $path );
	$mount->mkdir( $where, $mode, $callback );

	return;
}

sub rmdir {
	my( $self, $path, $callback ) = @_;

	my( $mount, $where ) = $self->_findmount( $path );
	$mount->rmdir( $where, $callback );

	return;
}

sub readdir {
	my( $self, $path, $callback ) = @_;

	my( $mount, $where ) = $self->_findmount( $path );
	$mount->readdir( $where, $callback );

	return;
}

sub load {
	# have to leave @_ alone so caller will get proper $data reference :(
	my $self = shift;
	my $path = shift;

	my( $mount, $where ) = $self->_findmount( $path );
	$mount->load( $where, $_[0], $_[1] );

	return;
}

sub copy {
	my( $self, $srcpath, $dstpath, $callback ) = @_;

	# FIXME we theoretically could copy across mounts by implementing it ourself, but I'm lazy now :)
	my( $mount, $where ) = $self->_findmount( $srcpath );
	my( $mount2, $where2 ) = $self->_findmount( $dstpath );
	if ( $mount != $mount2 ) {
		if ( DEBUG ) {
			warn 'copying across mounts is not supported by the Dispatcher!';
		}
		$callback->( 0 );
		return;
	}

	$mount->copy( $where, $where2, $callback );

	return;
}

sub move {
	my( $self, $srcpath, $dstpath, $callback ) = @_;

	# FIXME we theoretically could move across mounts by implementing it ourself, but I'm lazy now :)
	my( $mount, $where ) = $self->_findmount( $srcpath );
	my( $mount2, $where2 ) = $self->_findmount( $dstpath );
	if ( $mount != $mount2 ) {
		if ( DEBUG ) {
			warn 'moving across mounts is not supported by the Dispatcher!';
		}
		$callback->( -1 );	# FIXME what's the proper failure code?
		return;
	}

	$mount->move( $where, $where2, $callback );

	return;
}

sub scandir {
	my( $self, $path, $maxreq, $callback ) = @_;

	my( $mount, $where ) = $self->_findmount( $path );
	$mount->scandir( $where, $maxreq, $callback );

	return;
}

sub rmtree {
	my( $self, $path, $callback ) = @_;

	my( $mount, $where ) = $self->_findmount( $path );

	# we disallow rmtree if there's a mount under the path ( because of complications )
	my $matches = grep { $_ =~ /^$path.+/ } ( keys %{ $self->{'mounts'} } );
	if ( $matches ) {
		if ( DEBUG ) {
			warn 'rmtree across mounts is not supported by the Dispatcher!';
		}
		$callback->( -1 );	# FIXME what's the proper failure code?
	} else {
		$mount->rmtree( $where, $callback );
	}

	return;
}

sub fsync {
	my( $self, $fh, $callback ) = @_;

	# get the proper mount
	my $mapping = $self->_resolve_fh( $fh );
	if ( defined $mapping ) {
		if ( exists $self->{'fhmap'}->{ $mapping } ) {
			my( $mount, undef ) = $self->_findmount( $self->{'fhmap'}->{ $mapping } );

			$mount->fsync( $fh, $callback );
		} else {
			die "internal inconsistency - unknown fh: $fh";
		}
	} else {
		die "internal inconsistency - unknown fh: $fh";
	}

	return;
}

sub fdatasync {
	my( $self, $fh, $callback ) = @_;

	# get the proper mount
	my $mapping = $self->_resolve_fh( $fh );
	if ( defined $mapping ) {
		if ( exists $self->{'fhmap'}->{ $mapping } ) {
			my( $mount, undef ) = $self->_findmount( $self->{'fhmap'}->{ $mapping } );

			$mount->fdatasync( $fh, $callback );
		} else {
			die "internal inconsistency - unknown fh: $fh";
		}
	} else {
		die "internal inconsistency - unknown fh: $fh";
	}

	return;
}

1;
__END__

=for stopwords umount xantus AIO callback linux rmtree rootfs submount API Unmounts callbacks AnnoCPAN CPAN CPANTS Kwalitee RT com diff github

=head1 NAME

Filesys::Virtual::Async::Dispatcher - Multiple filesystems mounted on a single filesystem

=head1 SYNOPSIS

	#!/usr/bin/perl
	use strict; use warnings;
	use Fcntl qw( :DEFAULT :mode );	# S_IFREG S_IFDIR, O_SYNC O_LARGEFILE etc

	# uncomment this to enable debugging
	#sub Filesys::Virtual::Async::Dispatcher::DEBUG { 1 }

	use Filesys::Virtual::Async::Plain;
	use Filesys::Virtual::Async::Dispatcher;

	# create the root filesystem
	my $rootfs = Filesys::Virtual::Async::Plain->new( 'root' => $ENV{'PWD'} );

	# create the extra filesystems
	my $tmpfs = Filesys::Virtual::Async::Plain->new( 'root' => '/tmp' );
	my $procfs = Filesys::Virtual::Async::Plain->new( 'root' => '/proc' );

	# put it all together
	my $vfs = Filesys::Virtual::Async::Dispatcher->new( 'rootfs' => $rootfs );
	$vfs->mount( '/tmp', $tmpfs );
	$vfs->mount( '/tmp/proc', $procfs );

	# use $vfs as you wish!
	$vfs->readdir( '/tmp/proc', sub {	# should access the $procfs object
		my $data = shift;
		if ( defined $data ) {
			foreach my $e ( @$data ) {
				print "entry in /tmp/proc -> $e\n";
			}
			print "end of listing for /tmp/proc\n";
		} else {
			print "error reading /tmp/proc\n";
		}
	} );

=head1 ABSTRACT

Using this module will enable you to "mount" objects onto a filesystem and properly map methods to them.

=head1 DESCRIPTION

This module allows you to have arbitrary combinations of L<Filesys::Virtual::Async> objects mounted and expose a
single filesystem. The dispatcher will correctly map methods to the proper object based on their path in the
filesystem. This works similar to the way linux manages mounts in a single "visible" filesystem.

It might be a bit confusing on how the paths work at first. I'm sure with a bit of experimentation and looking
at the documentation for the Filesys::Virtual::Async::XYZ subclass, you'll get it!

This module makes extensive use of the functions in L<File::Spec> to be portable, so it might trip you up if
you are developing on a linux box and trying to mount '/foo' on a win32 box :)

=head2 Initializing the dispatcher

This constructor accepts either a hashref or a hash, valid options are:

=head3 rootfs

This sets the L<Filesys::Virtual::Async> object that will manage the "root" filesystem.

If this argument is undefined or not a proper subclass of L<Filesys::Virtual::Async> new() will die.

=head2 Methods

There is only two methods you can use, because this module does nothing except dispatch method calls to the
proper object.

=head3 mount

Mounts a new L<Filesys::Virtual::Async> object on the rootfs. Takes two arguments: the path and the object.

Returns true on success, false on failure.

Possible failure reasons:

=over 4

=item undefined path

=item undefined object or not proper subclass of Filesys::Virtual::Async

=item another object already mounted on path

=back

NOTE: This module is currently a bit stupid. It will allow mounts on non-existent directories! This could cause
weirdness when trying to do operations on the parent directory. This will be rectified in a future version, once I
get my head around the callbacks and figure out a new API to mount with a callback...

=head3 umount

Unmounts a mounted L<Filesys::Virtual::Async> object. Takes one argument: the path.

Returns true on success, false on failure.

=head2 Special Cases

Currently, this module does a pretty good job of dispatching methods to the proper object. However, there are some
methods which have exceptions to this rule.

=head3 root

Unimplemented, please do it directly on the object you are mounting onto the dispatcher.

=head3 stat/lstat

Array mode not supported because it would require extra munging on my part to get the paths right.

=head3 link/symlink

Linking across mounts is not supported because it would be crazy to keep the mapping in the dispatcher.

=head3 rename/copy/move

Doing these operations across mounts is not supported. Theoretically I could implement this in the dispatcher
but it would have to happen in a future version :)

=head3 rmtree

Deleting a directory which contains another mount in it is not supported. This could be done but we would have to
dig into the AIO code to make sure it stops deleting when it encounters the submount...

=head2 Debugging

You can enable debug mode which prints out some information ( and especially error messages ) by doing this:

	sub Filesys::Virtual::Async::Dispatcher::DEBUG () { 1 }
	use Filesys::Virtual::Async::Dispatcher;

=head1 EXPORT

None.

=head1 SEE ALSO

L<Filesys::Virtual::Async>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Filesys::Virtual::Async::Dispatcher

=head2 Websites

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Filesys-Virtual-Async-Dispatcher>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Filesys-Virtual-Async-Dispatcher>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Filesys-Virtual-Async-Dispatcher>

=item * CPAN Forum

L<http://cpanforum.com/dist/Filesys-Virtual-Async-Dispatcher>

=item * RT: CPAN's Request Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Filesys-Virtual-Async-Dispatcher>

=item * CPANTS Kwalitee

L<http://cpants.perl.org/dist/overview/Filesys-Virtual-Async-Dispatcher>

=item * CPAN Testers Results

L<http://cpantesters.org/distro/F/Filesys-Virtual-Async-Dispatcher.html>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Filesys-Virtual-Async-Dispatcher>

=item * Git Source Code Repository

This code is currently hosted on github.com under the account "apocalypse". Please feel free to browse it
and pull from it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/apocalypse/perl-filesys-virtual-async-dispatcher>

=back

=head2 Bugs

Please report any bugs or feature requests to C<bug-filesys-virtual-async-dispatcher at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Filesys-Virtual-Async-Dispatcher>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to xantus who got me motivated to write this :)

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
