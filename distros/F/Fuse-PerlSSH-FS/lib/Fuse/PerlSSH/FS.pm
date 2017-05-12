package Fuse::PerlSSH::FS;

use strict;
use warnings;

use Data::Dumper;
use IPC::PerlSSH;
use Fuse ':xattr';
use POSIX qw(ENOENT ENOSYS EEXIST EPERM O_RDONLY O_RDWR O_APPEND O_CREAT EOPNOTSUPP);
use Fcntl qw(S_ISBLK S_ISCHR S_ISFIFO);

our $VERSION = '0.13';
our $self;

sub new {
	my $class = shift;

	$self = bless({
		host => undef,
		port => 22,
		user => undef,
		root => '/',
		umask=> umask(),
		@_
	}, $class);

	die "Options to Fuse::PerlSSH::FS should be key/value pairs passed in as a hash (got an odd number of elements)" if @_ % 2 != 0;
	die "Fuse::PerlSSH::FS needs a host to work" if !$self->{host};
	die "Fuse::PerlSSH::FS only accepts password interactively!" if $self->{password};

	$self->{root} = '/' if !$self->{root};
	chop($self->{root}) if length($self->{root}) > 1 && $self->{root} =~ /\/$/;	# chop trailing slashes

	print STDERR '## Fuse::PerlSSH::FS::self'.Dumper($self) if $self->{debug};

	## setup ssh connection to remote host
	$self->_remote();

	## test remote capabilities
	eval { %{$self->{capabilities}} = $self->_remote->call("test_capabilities",$self->{root}); };
	die "Fuse::PerlSSH::FS capabilities test failed! $@" if $@;
	unless($self->{capabilities}->{can_xattr}){
		my $testfile = '/perlsshfs-xattr-test-'.time();
		my $mknod = local_mknod($testfile, 33204,0);
		my $setxattr = local_setxattr($testfile, 'user.abc','123',0);
		my $val = local_getxattr($testfile, 'user.abc');
		my $unlink = local_unlink($testfile, 'user.abc');
		$self->{capabilities}->{can_xattr} = 2 if $val eq '123';
		print STDERR "## test_capabilities xattr with testfile: mknod:$mknod, setxattr:$setxattr, val:$val, unlink:$unlink \n" if $self->{debug};
	}
	print STDERR "## new: test_capabilities: ".Dumper($self->{capabilities}) if $self->{debug};

	return $self;
}

sub _remote {
	my $self = shift || $self;

	if( !$self->{ssh} ){
		$self->{ssh} = IPC::PerlSSH->new( Host => $self->{host}, Port => $self->{port}, User => $self->{user} );

		if( $self->{ssh} ){
			$self->{ssh}->store(
				test_connection => q{ return "HELO"; },
				test_capabilities => q{
					my $root = shift;

					eval { require File::ExtAttr; };
					my $xattr_module = $@ ? $@ : 1;

					eval { require Filesys::DfPortable; };
					my $dfportable_module = $@ ? $@ : 1;

					my @mount = `mount`;
					my $can_xattr = 1 if $mount[0] =~ /,user_xattr/;

					return ('remote_perl_version', $], 'xattr_module', $xattr_module, 'dfportable_module', $dfportable_module, 'can_xattr', $can_xattr);
				},
			#	remote_mknod    => q{ require 'syscall.ph'; syscall(&SYS_mknod,$_[0],$_[1],$_[2]); },	# creates unusable socket files! (probably a problem with dec vs. oct mode, todo: lookup what the syscall requires..)
				remote_mknod    => q{	# todo: replace with Unix::Mknod
							# todo: does not use mode/dev
					my $result = open(my $fh,'>', $_[0]) or die "Cannot mknod/open('$_[0]') - $!";
					close($fh);
					return $result;
				},
				remote_mkdir    => q{	# because PerlSSH's mkdir does not propagate the 2nd param $mode (mask)
					my $result = mkdir($_[0],$_[1]) or die "Cannot mkdir('$_[0]','$_[1]') - $!";
					return $result;
				},
				remote_link     => q{ return link($_[0],$_[1]) or die "Cannot link('$_[0]','$_[1]') - $!"; },
				remote_truncate => q{	# because PerlSSH's truncate only works on filehandles
					return truncate($_[0],$_[1]) or die "Cannot truncate('$_[0]','$_[1]') - $!";
				},
				remote_readdir  => q{	# because PerlSSH's readdir removes dotfiles
					opendir( my $dh, $_[0] ) or die "Cannot opendir('$_[0]') - $!";
					my @ents = readdir($dh);
					return @ents;
				},
				statfs	=> q{
					# @_ = (root,method)
					my ($blocks,$bavail) = (10000000,5000000);
					if($_[1] eq 'dfportable'){
						my $df = dfportable($_[0]);
						$blocks = $df->{blocks} if defined($df);
						$bavail = $df->{bavail} if defined($df);
					}elsif($_[1] eq 'df'){
						my @df = `df $_[0]`;
						(my $fsystem,$blocks,my $bused,$bavail,my $capacity,my $mounted) = split(/\s+/,$df[1]);
						$blocks = $blocks if $df[1];
						$bavail = $bavail if $df[1];
					}

					return (255,1000000,500000,$blocks,$bavail,1024);
				}, # a pseudo statfs
				remote_listxattr => q{
					use File::ExtAttr;
					my @list = File::ExtAttr::listfattr($_[0]) or die "Cannot listfattr('$_[0]') - $!";
					for(@list){ $_ = 'user.'.$_ if $_ !~ /\./; } # fix missing ns
					return @list;
				},
				remote_getxattr => q{
					use File::ExtAttr;
					die "Cannot getfattr('$_[0]','$_[1]') - no namespace" if $_[1] !~ /\./;
					my ($ns,$key) = split(/\./,$_[1],2);
				#	return " (".$ns.":$key) ".File::ExtAttr::getfattr($_[0], $key, { namespace => $ns }) or die "Cannot getfattr('$_[0]','$_[1]') - $!";
					return File::ExtAttr::getfattr($_[0], $key, { namespace => $ns }) or die "Cannot getfattr('$_[0]','$_[1]') - $!";
				},
				remote_setxattr => q{
					use File::ExtAttr;
					die "Cannot setfattr('$_[0]','$_[1]','$_[2]','$_[3]') - no namespace" if $_[1] !~ /\./;
					my ($ns,$key) = split(/\./,$_[1],2);

					# File::ExtAttr: %flags allows control of whether the attribute should be created or should replace an existing attribute's value.
					# If the key create is true, setfattr will fail if the attribute already exists. If the key replace is true, setfattr will fail if the attribute does not already exist. If neither is specified, then the attribute will be created (if necessary) or silently replaced.
					my %flags = (create => 1);
					%flags = (replace => 1) if $_[3] > 1; # OR-ed constants are XATTR_CREATE 1, XATTR_REPLACE 2
					return File::ExtAttr::setfattr($_[0], $key, $_[2], { namespace => $ns, %flags }) or die "Cannot setfattr('$_[0]','$_[1]','$_[2]','$_[3]') - $!";
				},
				remote_removexattr => q{
					use File::ExtAttr;
					die "Cannot delfattr('$_[0]','$_[1]') - no namespace" if $_[1] !~ /\./;
					my ($ns,$key) = split(/\./,$_[1],2);
					File::ExtAttr::delfattr($_[0], $key, { namespace => $ns }) or die "Cannot delfattr('$_[0]','$_[1]') - $!";
				},
			);
			$self->{ssh}->use_library('FS', qw( chown chmod lstat readlink rename rmdir symlink unlink utime ) );
			$self->{ssh}->use_library('Fuse::PerlSSH::RemoteFunctions');

			my $rval;
			eval { $rval = $self->_remote->call("test_connection"); };
			die "Fuse::PerlSSH::FS ssh connection not working!" if $@;
			print STDERR "## _remote: test_connection: ".Dumper($rval) if $self->{debug};
		}else{
			die "Fuse::PerlSSH::FS was not able to log in to host $self->{host} on port $self->{port} with user $self->{user}";
			return undef;
		}
	}
	
	return $self->{ssh};
}

sub mount {
	my $self = shift;

	## check local mount point
	if(!-d $self->{mountpoint}){
		die 'Fuse::PerlSSH::FS: Mountpoint '.$self->{mountpoint}.' does not exists!';
	}

	my %add_xattr;
	if($self->{no_xattr}){
		print STDERR "## mount: xattr bindings omitted. --no-xattr option in effect.\n" if $self->{debug};
	}elsif(!$self->{capabilities}->{can_xattr}){
		print STDERR "## mount: xattr bindings omitted. Remote host seems to be incapable.\n" if $self->{debug};
	}else{
		%add_xattr = (
			listxattr=> \&local_listxattr,
			getxattr => \&local_getxattr,
			setxattr => \&local_setxattr,
			removexattr=>\&local_removexattr,
		);
	}

	my %fuse = (
		mountpoint => $self->{mountpoint},
		threaded   => $self->{threaded} ? 1 : 0,
		debug	   => $self->{debug} > 1 ? 1 : 0,

		readdir	 => \&local_readdir,
		getattr	 => \&local_getattr,
		mknod	 => \&local_mknod,
		mkdir	 => \&local_mkdir,
		rmdir	 => \&local_rmdir,
		rename	 => \&local_rename,
		unlink	 => \&local_unlink,
		open	 => \&local_open,
		read	 => \&local_read,
		write	 => \&local_write,
		release	 => \&local_release,
		symlink	 => \&local_symlink,
		link	 => \&local_link,
		readlink => \&local_readlink,
		utime	 => \&local_utime,
		truncate => \&local_truncate,
		ftruncate=> \&local_ftruncate,
		statfs	 => \&local_statfs,
		%add_xattr
	);

	Fuse::main( %fuse );
	return;
}

sub umount {
	my $self = shift;
	print STDERR "## umount: sending 'exit'\n" if $self->{debug};
	eval { 	$self->_remote->eval('exit 1'); };
}

sub path {
	return $self->{root} if $_[0] eq '/';
	return $self->{root} . $_[0];
}

sub local_readdir {
	my $path = path(shift);
	print STDERR "## local_readdir: $path \n" if $self->{debug};

	my @dir;
	eval { 	@dir = _remote->call("remote_readdir", $path ); };
	return -ENOENT() if $@;

	return @dir ? (@dir, 0) : 0;
}

sub local_getattr {
	my $path = path(shift);
	print STDERR "## local_getattr: $path \n" if $self->{debug};

	## Fuse-perl docs say "FIXME: the "ino" field is currently ignored. I tried setting it to 0 in an example script, which consistently caused segfaults."
	## $stat[1] = 0; # in case we get segfaults

	my @stat;
	eval { @stat = _remote->call("lstat", $path ); };

	return -ENOENT() if $@; # ENOENT = "file not found"
	return @stat;
}

## Arguments: New directory pathname, numeric modes. Returns an errno.
## Called to create a directory.
sub local_mkdir {
	my $path = path(shift);
	my $mode = shift;

	## pass the "mode as modified by umask"
#	$mode &= ~$self->{umask} if defined $mode;

	print STDERR "## local_mkdir: $path perm:decimal($mode),octal(".sprintf("%o", $mode).")\n" if $self->{debug};

	my $result;
	eval { $result = _remote->call("remote_mkdir", $path, $mode ); };

	return -ENOENT() if $@;
	return $result ? 0 : -$!;
}

## Arguments: Filename, numeric modes, numeric device Returns an errno (0 upon success, as usual).
## This function is called for all non-directory, non-symlink nodes, not just devices.
sub local_mknod {
	my $path = path(shift);
	my $mode = shift;
	my $dev = shift;
	print STDERR "## local_mknod: $path perm:decimal($mode),octal(".sprintf("%o", $mode)."), dev:$dev\n" if $self->{debug};

	# from Fuse::PDF: don't support special files
#	my $is_special = !S_ISREG($mode) && !S_ISDIR($mode) && !S_ISLNK($mode);
#	return -EIO() if $is_special;

	# since this is called for ALL files, not just devices, I'll do some checks
	# and possibly run the real mknod command.
	$! = 0;

	## pass the "mode as modified by umask"
#	$mode &= ~$self->{umask} if defined $mode;

	my $result;
	eval { $result = _remote->call("remote_mknod", $path,$mode,$dev ); };

	return -ENOENT() if $@;
	return $result ? 0 : -$!;
}


## Arguments: Pathname. Returns an errno.
## Called to remove a directory.
sub local_rmdir {
	my $path = path(shift);
	print STDERR "## local_rmdir: $path\n" if $self->{debug};

	my $result;
	eval { $result = _remote->call("rmdir", $path ); };

	return -ENOENT() if $@;
	return $result ? 0 : -$!;
}

## Arguments: old filename, new filename. Returns an errno.
## Called to rename a file, and/or move a file from one directory to another.
sub local_rename {
	my $path = path(shift);
	my $newpath = path(shift);
	print STDERR "## local_rename: $path -> $newpath\n" if $self->{debug};

	my $result;
	eval { $result = _remote->call("rename", $path, $newpath ); };

	return -ENOENT() if $@;
	return $result ? 0 : -$!;
}


## Arguments: Filename. Returns an errno.
## Called to remove a file, device, or symlink.
sub local_unlink {
	my $path = path(shift);
	print STDERR "## local_unlink: $path\n" if $self->{debug};

	my $result;
	eval { $result = _remote->call("unlink", $path ); };

	return -ENOENT() if $@;
	return $result ? 0 : -$!;
}

sub local_open {
	my $path = path(shift);
	my $mode = shift;
#	my $fileinfo = shift;
	print STDERR "## local_open: $path mode:$mode," if $self->{debug};

	my $fd;
	eval { $fd = _remote->call("sysopen", $mode, $path ); };
	print STDERR " fd:$fd\n" if $self->{debug};

	if($@){
		print STDERR "##  local_open: remote_sysopen failed: $@\n" if $self->{debug};
		return -ENOENT();
	}

	return -$! unless $fd;

	return (0,$fd);
}

## Arguments: Pathname, numeric requested size, numeric offset, file handle Returns a numeric errno, or a string scalar with up to $requestedsize bytes of data.
## Called in an attempt to fetch a portion of the file.
sub local_read {
	my ($path,$length,$offset,$fd) = @_;
	$path = path(shift);
	print STDERR "## local_read: $path length:$length, offset:$offset, fd:$fd\n" if $self->{debug};

	return -ENOENT() unless $fd;	# as good as checking if the file exists, no handle, no file

	my $buf = -ENOSYS();	# init return_value with an error, in case we can't fill it with data
	eval { $buf = _remote->call("read", $fd, $length, $offset ); };

	return -ENOSYS() if $@;
	return $buf;
}

## Arguments: Pathname, scalar buffer, numeric offset, file handle. You can use length($buffer) to find the buffersize. Returns length($buffer) if successful (number of bytes written).
## Called in an attempt to write (or overwrite) a portion of the file. Be prepared because $buffer could contain random binary data with NULs and all sorts of other wonderful stuff.
sub local_write {
	my ($path,$buf,$offset,$fd) = @_;
	$path = path(shift);
	print STDERR "## local_write: $path buf-length:".length($buf).", offset:$offset, fd:$fd\n" if $self->{debug};

	return -ENOSYS() unless $fd;	# as good as checking if the file exists, no handle, no file

	# write sadly does not return how many bytes were written
	eval { _remote->call( "write", $fd, $buf, $offset ) };
	if($@){
		print STDERR "##  local_write: write failed: $@\n" if $self->{debug};
		return -ENOSYS();
	}

	return length($buf);
}

## Arguments: Pathname, numeric flags passed to open, file handle Returns an errno or 0 on success.
## Called to indicate that there are no more references to the file. Called once for every file with the same pathname and flags as were passed to open.
sub local_release {
	my $path = path(shift);
	my $mode = shift;
	my $fd = shift;

	print STDERR "## local_release: $path mode:$mode, fd:$fd\n" if $self->{debug};

	return -ENOSYS() unless $fd;

	my $result;
	eval { $result = _remote->call( "close", $fd ); };

	return -ENOENT() if $@;

	return $result ? 0 : -$!;
	return 0;
}

## Arguments: Existing filename, symlink name. Returns an errno.
## Called to create a symbolic link.
sub local_symlink {
	my $path = shift;
	my $sympath = path(shift);
	print STDERR "## local_symlink: $path <- $sympath\n" if $self->{debug};

	my $result;
	eval { $result = _remote->call("symlink", $path, $sympath ); };

	return -ENOENT() if $@;
	return $result ? 0 : -EEXIST(); # if symlink fails, most probably, because it exists
}

## Arguments: Existing filename, hardlink name. Returns an errno.
## Called to create hard links.
sub local_link {
	my $path = path(shift);
	my $linkpath = path(shift);
	print STDERR "## local_link: $path -> $linkpath\n" if $self->{debug};

	my $result;
	eval { $result = _remote->call("remote_link", $path, $linkpath ); };

	return -ENOENT() if $@;
	return $result ? 0 : -EEXIST(); # if link fails, most probably, because it exists
}

## Arguments: link pathname. Returns a scalar: either a numeric constant, or a text string.
## This is called when dereferencing symbolic links, to learn the target.
sub local_readlink {
	my $path = path(shift);
	print STDERR "## local_readlink: $path\n" if $self->{debug};

	my $result;
	eval { $result = _remote->call("readlink", $path ); };

	return -ENOENT() if $@;
	return $result ? $result : -$!;
}

## Arguments: Pathname, numeric actime, numeric modtime. Returns an errno.
## Called to change access/modification times for a file/directory/device/symlink.
sub local_utime {
	## arg order is reversed between perl (path(s) last, and what is passed-in here (path first), probably because the perl way is not atomic as it may die after a few files, and the fuse way makes it atomic: one file at a time
	my $path = path(shift);
	my ($atime,$mtime) = (shift,shift);
	print STDERR "## local_utime: $path atime:$atime,mtime:$mtime\n" if $self->{debug};

	my $result;
	eval { $result = _remote->call("utime", $atime, $mtime, $path ); };

	return -ENOENT() if $@;
	return $result ? 0 : -$!;
}

sub local_truncate {
	my $path = path(shift);
	my $offset = shift;
	print STDERR "## local_truncate: $path offset:$offset\n" if $self->{debug};

	my $result;
	eval { $result = _remote->call("remote_truncate", $path, $offset ); };

	return -ENOENT() if $@;
	return $result ? 0 : -$!;
}

## Arguments: Pathname, numeric offset. Returns an errno.
## Called to truncate a file, at the given offset.
## sub x_truncate { return truncate(fixup(shift),shift) ? 0 : -$! ; }
sub local_ftruncate {
	my $path = path(shift);
	my $offset = shift;
	my $fd = shift;
	print STDERR "## local_ftruncate: $path offset:$offset, fd:$fd\n" if $self->{debug};

	my $result;
	eval { $result = _remote->call("truncate", $fd, $offset ); };	# as PerlSSH's truncate *only* operates on filehandles, resolved via fd, it's effectively a ftruncate() (see FUSE docs for that)

	return -ENOENT() if $@;
	return $result ? 0 : -$!;
}

## Arguments: none, Returns any of the following:
## -ENOANO()
## or $namelen, $files, $files_free, $blocks, $blocks_avail, $blocksize
## or -ENOANO(), $namelen, $files, $files_free, $blocks, $blocks_avail, $blocksize
sub local_statfs {
	my @statfs;

	my $method = $self->{capabilities}->{dfportable_module} eq 1 ? 'dfportable' : 'df';

	eval { @statfs = _remote->call("statfs", $self->{root}, $method ); };
	print STDERR "## local_statfs root:$self->{root}, method:$method, (@statfs)\n" if $self->{debug};

	return -ENOENT() if $@;
	return @statfs;
}

sub local_listxattr {
	my $path = path(shift);
	print STDERR "## listxattr: $path \n" if $self->{debug};

	my @list;
	eval { @list = _remote->call("remote_listxattr", $path ); };
	return -ENOENT() if $@;

	print STDERR "##  local_listxattr: list:@list\n" if $self->{debug};

	return @list ? (@list, 0) : 0;
}

sub local_getxattr {
	my $path = path(shift);
	my $key = shift;
	print STDERR "## local_getxattr: $path key:$key\n" if $self->{debug};

	my $val;
	eval { $val = _remote->call("remote_getxattr", $path, $key ); };
	print STDERR "##  local_getxattr: eval:$@ \n" if $self->{debug};
	return -EOPNOTSUPP() if $@ =~ / no namespace /;
	return -ENOSYS() if $@;

	print STDERR "##  local_getxattr: ".$key."=".($val||'<undef>')." \n" if $self->{debug};

	return $val ? $val : 0;
}

sub local_setxattr {
	my $path = path(shift);
	my $key = shift;
	my $val = shift;
	my $create_replace = shift;
	print STDERR "## local_setxattr: $path key:$key, val:$val, create|replace:$create_replace\n" if $self->{debug};

	my $ret;
	eval { $ret = _remote->call("remote_setxattr", $path, $key, $val, $create_replace ); };
	print STDERR "##  local_setxattr: ret:".($ret||'<undef>').", eval:$@ \n" if $self->{debug};
	return -EOPNOTSUPP() if $@ =~ / no namespace /;	# we force the user only to supply a namespace
#	return -EEXIST() if !defined($ret);	# If flags is set to XATTR_CREATE and the extended attribute already exists, this should fail with - EEXIST.
#	return -ENOATTR() if $@ =~ / no data available/;	# If flags is set to XATTR_REPLACE and the extended attribute doesn't exist, this should fail with - ENOATTR.

	return -ENOSYS() if $@;

	return $ret ? 0 : $create_replace ? -ENOSYS() : -EEXIST(); # ENOATTR() is missing, thus ENOSYS
}

sub local_removexattr {
	my $path = path(shift);
	my $key = shift;
	print STDERR "## local_removexattr: $path key:$key\n" if $self->{debug};

	my ($ret,$err);
	eval { ($ret,$err) = _remote->call("remote_removexattr", $path, $key ); };
	print STDERR "##  local_removexattr: ret:".($ret||'<undef>').", eval:$@ \n" if $self->{debug};
	return -EOPNOTSUPP() if $@ =~ / no namespace /;
	return -ENOSYS() if $@;

#	return -ENOATTR() if !defined($ret); #  if $@ =~ / no data available/;
	return $ret ? 0 : -ENOSYS(); # ENOATTR() is missing, thus ENOSYS
}


1;

__END__

=head1 NAME

Fuse::PerlSSH::FS - Mount a remote filesystem via FUSE and PerlSSH

=head1 SYNOPSIS

  use Fuse::PerlSSH::FS;
  my $fpfs = Fuse::PerlSSH::FS->new(
	host => 'example.com',
	port => 22,
	user => 'user',
	mountpoint => '/mnt/remote',
  );
  $fpfs->mount();

=head1 DESCRIPTION

The mounting script L<perlsshfs> found in this distribution and its backend module
L<Fuse::PerlSSH::FS> (this here) is meant as a drop-in replacement for
L<sshfs|http://fuse.sourceforge.net/sshfs.html>, written in Perl. The primary goal, for
now, is to add extended file attribute (xattr) functionality to the mounted filesystem
and only later to achieve the full feature-level of sshfs.

=head2 Why would I want to use perlsshfs and not sshfs?

The sole motivation behind doing this is that sshfs won't support extended file attributes
(I<xattr>) anytime soon, as it relies on openssh's "internal FTP server". SFTP doesn't expose
functions to manipulate extended attributes on remote files, thus the sshfs developers tend
to ignore xattr. (Although there's a patched version of sshfs floating around that in turn
requires a patched version of openssh..)

=head1 METHODS

Right now, the module offers some OO-ish methods, and some plain functions. The mounting
script uses the below OO methods new(), mount() and umount(). But note the quirk that
$self is stored in a global I<our> variable, to mediate between the OO API and the 
Fuse-style functions.

=head2 new()

=head2 mount()

=head2 umount()

=head1 FUNCTIONS

A growing list of functions that match the FUSE bindings, all prefixed by "local_":

  local_readdir,
  local_getattr,
  local_mknod,
  local_mkdir,
  local_rmdir,
  local_rename,
  local_unlink,
  local_open,
  local_read,
  local_write,
  local_release,
  local_symlink,
  local_link,
  local_readlink,
  local_utime,
  local_truncate,
  local_ftruncate,
  local_statfs,
  local_listxattr,
  local_getxattr,
  local_setxattr,
  local_removexattr,

=head1 EXPORT

None by default.

=head1 CAVEATS or TODO

=head2 Reliability

Most tests via L<Test::Virtual::Filesystem> succeed but some still fail. So keep in mind
that this is beta quality code and don't rely on it to transfer critical data.

=head2 Remote "capabilities"

This module here requires Perl to be installed on the remote machine and L<File::ExtAttr>
to be installed. On connect some rudimentary checks are performed to find out what the
remote system is able to do, especially regarding xattribs - but that might not reveal any 
problem. So make sure the remote file-system is able to accept xattr calls (is mounted
with the I<user_xattr> option, or similar, on non *nix systems) and that the ssh host
has File::ExtAttr in place, if you want to use xattribs.

=head2 (Local) FUSE limitations

Keep in mind that even when the underlying filesystem on the remote end has everything in
place for extended attribs, your local stack might be incomplete. As of this writing,
FUSE implementations on NetBSD and FreeBSD do not support xattr, for example.

=head2 No keep-alive

Currently, there's no keep-alive mechanism and the automatic reconnect generally fails.
So the mount might become unresponsive after a certain time of inactivity.

=head1 SEE ALSO

L<FUSE|Fuse>, L<IPC::PerlSSH>. L<Filesys::Virtual::SSH>.

=head1 AUTHOR

Clipland GmbH L<http://www.clipland.com/>

=head1 COPYRIGHT & LICENSE

Copyright 2012-2013 Clipland GmbH. All rights reserved.

This library is free software, dual-licensed under L<GPLv3|http://www.gnu.org/licenses/gpl>/L<AL2|http://opensource.org/licenses/Artistic-2.0>.
You can redistribute it and/or modify it under the same terms as Perl itself.