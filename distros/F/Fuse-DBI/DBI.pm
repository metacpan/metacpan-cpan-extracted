#!/usr/bin/perl

package Fuse::DBI;

use 5.008;
use strict;
use warnings;

use POSIX qw(ENOENT EISDIR EINVAL ENOSYS O_RDWR);
use Fuse;
use DBI;
use Carp;
use Data::Dumper;

our $VERSION = '0.08';

# block size for this filesystem
use constant BLOCK => 1024;

=head1 NAME

Fuse::DBI - mount your database as filesystem and use it

=head1 SYNOPSIS

  use Fuse::DBI;
  Fuse::DBI->mount( ... );

See C<run> below for examples how to set parameters.

=head1 DESCRIPTION

This module will use C<Fuse> module, part of C<FUSE (Filesystem in USErspace)>
available at L<http://fuse.sourceforge.net/> to mount
your database as file system.

That will give you possibility to use normal file-system tools (cat, grep, vi)
to manipulate data in database.

It's actually opposite of Oracle's intention to put everything into database.


=head1 METHODS

=cut

=head2 mount

Mount your database as filesystem.

Let's suppose that your database have table C<files> with following structure:

 id:		int
 filename:	text
 size:		int
 content:	text
 writable:	boolean

Following is example how to mount table like that to C</mnt>:

  my $mnt = Fuse::DBI->mount({
	'filenames' => 'select id,filename,size,writable from files',
	'read' => 'select content from files where id = ?',
	'update' => 'update files set content = ? where id = ?',
	'dsn' => 'DBI:Pg:dbname=test_db',
	'user' => 'database_user',
	'password' => 'database_password',
	'invalidate' => sub { ... },
  });

Options:

=over 5

=item filenames

SQL query which returns C<id> (unique id for that row), C<filename>,
C<size> and C<writable> boolean flag.

=item read

SQL query which returns only one column with content of file and has
placeholder C<?> for C<id>.

=item update

SQL query with two pace-holders, one for new content and one for C<id>.

=item dsn

C<DBI> dsn to connect to (contains database driver and name of database).

=item user

User with which to connect to database

=item password

Password for connecting to database

=item invalidate

Optional anonymous code reference which will be executed when data is updated in
database. It can be used as hook to delete cache (for example on-disk-cache)
which is created from data edited through C<Fuse::DBI>.

=item fork

Optional flag which forks after mount so that executing script will continue
running. Implementation is experimental.

=back

=cut

my $dbh;
my $sth;
my $ctime_start;

sub read_filenames;
sub fuse_module_loaded;

# evil, evil way to solve this. It makes this module non-reentrant. But, since
# fuse calls another copy of this script for each mount anyway, this shouldn't
# be a problem.
my $fuse_self;

sub mount {
	my $class = shift;
	my $self = {};
	bless($self, $class);

	my $arg = shift;

	print Dumper($arg);

	unless ($self->fuse_module_loaded) {
		print STDERR "no fuse module loaded. Trying sudo modprobe fuse!\n";
		system "sudo modprobe fuse" || die "can't modprobe fuse using sudo!\n";
	}

	carp "mount needs 'dsn' to connect to (e.g. dsn => 'DBI:Pg:dbname=test')" unless ($arg->{'dsn'});
	carp "mount needs 'mount' as mountpoint" unless ($arg->{'mount'});

	# save (some) arguments in self
	foreach (qw(mount invalidate)) {
		$self->{$_} = $arg->{$_};
	}

	foreach (qw(filenames read update)) {
		carp "mount needs '$_' SQL" unless ($arg->{$_});
	}

	$ctime_start = time();

	my $pid;
	if ($arg->{'fork'}) {
		$pid = fork();
		die "fork() failed: $!" unless defined $pid;
		# child will return to caller
		if ($pid) {
			my $counter = 4;
			while ($counter && ! $self->is_mounted) {
				select(undef, undef, undef, 0.5);
				$counter--;
			}
			if ($self->is_mounted) {
				return $self;
			} else {
				return undef;
			}
		}
	}

	$dbh = DBI->connect($arg->{'dsn'},$arg->{'user'},$arg->{'password'}, {AutoCommit => 0, RaiseError => 1}) || die $DBI::errstr;

	$sth->{'filenames'} = $dbh->prepare($arg->{'filenames'}) || die $dbh->errstr();

	$sth->{'read'} = $dbh->prepare($arg->{'read'}) || die $dbh->errstr();
	$sth->{'update'} = $dbh->prepare($arg->{'update'}) || die $dbh->errstr();


	$self->{'sth'} = $sth;

	$self->{'read_filenames'} = sub { $self->read_filenames };
	$self->read_filenames;

	$fuse_self = \$self;

	Fuse::main(
		mountpoint=>$arg->{'mount'},
		getattr=>\&e_getattr,
		getdir=>\&e_getdir,
		open=>\&e_open,
		statfs=>\&e_statfs,
		read=>\&e_read,
		write=>\&e_write,
		utime=>\&e_utime,
		truncate=>\&e_truncate,
		unlink=>\&e_unlink,
		rmdir=>\&e_unlink,
		debug=>0,
	);
	
	exit(0) if ($arg->{'fork'});

	return 1;

};

=head2 is_mounted

Check if fuse filesystem is mounted

  if ($mnt->is_mounted) { ... }

=cut

sub is_mounted {
	my $self = shift;

	my $mounted = 0;
	my $mount = $self->{'mount'} || confess "can't find mount point!";
	if (open(MTAB, "/etc/mtab")) {
		while(<MTAB>) {
			$mounted = 1 if (/ $mount fuse /i);
		}
		close(MTAB);
	} else {
		warn "can't open /etc/mtab: $!";
	}

	return $mounted;
}


=head2 umount

Unmount your database as filesystem.

  $mnt->umount;

This will also kill background process which is translating
database to filesystem.

=cut

sub umount {
	my $self = shift;

	if ($self->{'mount'} && $self->is_mounted) {
		system "( fusermount -u ".$self->{'mount'}." 2>&1 ) >/dev/null";
		if ($self->is_mounted) {
			system "sudo umount ".$self->{'mount'} ||
			return 0;
		}
		return 1;
	}

	return 0;
}

$SIG{'INT'} = sub {
	if ($fuse_self && $$fuse_self->umount) {
		print STDERR "umount called by SIG INT\n";
	}
};

$SIG{'QUIT'} = sub {
	if ($fuse_self && $$fuse_self->umount) {
		print STDERR "umount called by SIG QUIT\n";
	}
};

sub DESTROY {
	my $self = shift;
	if ($self->umount) {
		print STDERR "umount called by DESTROY\n";
	}
}

=head2 fuse_module_loaded

Checks if C<fuse> module is loaded in kernel.

  die "no fuse module loaded in kernel"
  	unless (Fuse::DBI::fuse_module_loaded);

This function in called by C<mount>, but might be useful alone also.

=cut

sub fuse_module_loaded {
	my $lsmod = `lsmod`;
	die "can't start lsmod: $!" unless ($lsmod);
	if ($lsmod =~ m/fuse/s) {
		return 1;
	} else {
		return 0;
	}
}

my %files;

sub read_filenames {
	my $self = shift;

	my $sth = $self->{'sth'} || die "no sth argument";

	# create empty filesystem
	(%files) = (
		'.' => {
			type => 0040,
			mode => 0755,
		},
		'..' => {
			type => 0040,
			mode => 0755,
		},
	#	a => {
	#		cont => "File 'a'.\n",
	#		type => 0100,
	#		ctime => time()-2000
	#	},
	);

	# fetch new filename list from database
	$sth->{'filenames'}->execute() || die $sth->{'filenames'}->errstr();

	# read them in with sesible defaults
	while (my $row = $sth->{'filenames'}->fetchrow_hashref() ) {
		$row->{'filename'} ||= 'NULL-'.$row->{'id'};
		$files{$row->{'filename'}} = {
			size => $row->{'size'},
			mode => $row->{'writable'} ? 0644 : 0444,
			id => $row->{'id'} || 99,
		};


		my $d;
		foreach (split(m!/!, $row->{'filename'})) {
			# first, entry is assumed to be file
			if ($d) {
				$files{$d} = {
						mode => 0755,
						type => 0040
				};
				$files{$d.'/.'} = {
						mode => 0755,
						type => 0040
				};
				$files{$d.'/..'} = {
						mode => 0755,
						type => 0040
				};
			}
			$d .= "/" if ($d);
			$d .= "$_";
		}
	}

	print "found ",scalar(keys %files)," files\n";
}


sub filename_fixup {
	my ($file) = shift;
	$file =~ s,^/,,;
	$file = '.' unless length($file);
	return $file;
}

sub e_getattr {
	my ($file) = filename_fixup(shift);
	$file =~ s,^/,,;
	$file = '.' unless length($file);
	return -ENOENT() unless exists($files{$file});
	my ($size) = $files{$file}{size} || 0;
	my ($dev, $ino, $rdev, $blocks, $gid, $uid, $nlink, $blksize) = (0,0,0,int(($size+BLOCK-1)/BLOCK),0,0,1,BLOCK);
	my ($atime, $ctime, $mtime);
	$atime = $ctime = $mtime = $files{$file}{ctime} || $ctime_start;

	my ($modes) = (($files{$file}{type} || 0100)<<9) + $files{$file}{mode};

	# 2 possible types of return values:
	#return -ENOENT(); # or any other error you care to
	#print "getattr($file) ",join(",",($dev,$ino,$modes,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)),"\n";
	return ($dev,$ino,$modes,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);
}

sub e_getdir {
	my ($dirname) = shift;
	$dirname =~ s!^/!!;
	# return as many text filenames as you like, followed by the retval.
	print((scalar keys %files)." files total\n");
	my %out;
	foreach my $f (sort keys %files) {
		if ($dirname) {
			if ($f =~ s/^\Q$dirname\E\///) {
				$out{$f}++ if ($f =~ /^[^\/]+$/);
			}
		} else {
			$out{$f}++ if ($f =~ /^[^\/]+$/);
		}
	}
	if (! %out) {
		$out{'no files? bug?'}++;
	}
	print scalar keys %out," files in dir '$dirname'\n";
	print "## ",join(" ",keys %out),"\n";
	return (keys %out),0;
}

sub read_content {
	my ($file,$id) = @_;

	die "read_content needs file and id" unless ($file && $id);

	$sth->{'read'}->execute($id) || die $sth->{'read'}->errstr;
	$files{$file}{cont} = $sth->{'read'}->fetchrow_array;
	# I should modify ctime only if content in database changed
	#$files{$file}{ctime} = time() unless ($files{$file}{ctime});
	print "file '$file' content [",length($files{$file}{cont})," bytes] read in cache\n";
}


sub e_open {
	# VFS sanity check; it keeps all the necessary state, not much to do here.
	my $file = filename_fixup(shift);
	my $flags = shift;

	return -ENOENT() unless exists($files{$file});
	return -EISDIR() unless exists($files{$file}{id});

	read_content($file,$files{$file}{id}) unless exists($files{$file}{cont});

	$files{$file}{cont} ||= '';
	print "open '$file' ",length($files{$file}{cont})," bytes\n";
	return 0;
}

sub e_read {
	# return an error numeric, or binary/text string.
	# (note: 0 means EOF, "0" will give a byte (ascii "0")
	# to the reading program)
	my ($file) = filename_fixup(shift);
	my ($buf_len,$off) = @_;

	return -ENOENT() unless exists($files{$file});

	my $len = length($files{$file}{cont});

	print "read '$file' [$len bytes] offset $off length $buf_len\n";

	return -EINVAL() if ($off > $len);
	return 0 if ($off == $len);

	$buf_len = $len-$off if ($len - $off < $buf_len);

	return substr($files{$file}{cont},$off,$buf_len);
}

sub clear_cont {
	print "transaction rollback\n";
	$dbh->rollback || die $dbh->errstr;
	print "invalidate all cached content\n";
	foreach my $f (keys %files) {
		delete $files{$f}{cont};
		delete $files{$f}{ctime};
	}
	print "begin new transaction\n";
	#$dbh->begin_work || die $dbh->errstr;
}


sub update_db {
	my $file = shift || die;

	$files{$file}{ctime} = time();

	my ($cont,$id) = (
		$files{$file}{cont},
		$files{$file}{id}
	);

	if (!$sth->{'update'}->execute($cont,$id)) {
		print "update problem: ",$sth->{'update'}->errstr;
		clear_cont;
		return 0;
	} else {
		if (! $dbh->commit) {
			print "ERROR: commit problem: ",$sth->{'update'}->errstr;
			clear_cont;
			return 0;
		}
		print "updated '$file' [",$files{$file}{id},"]\n";

		$$fuse_self->{'invalidate'}->() if (ref $$fuse_self->{'invalidate'});
	}
	return 1;
}

sub e_write {
	my $file = filename_fixup(shift);
	my ($buffer,$off) = @_;

	return -ENOENT() unless exists($files{$file});

	my $cont = $files{$file}{cont};
	my $len = length($cont);

	print "write '$file' [$len bytes] offset $off length ",length($buffer),"\n";

	$files{$file}{cont} = "";

	$files{$file}{cont} .= substr($cont,0,$off) if ($off > 0);
	$files{$file}{cont} .= $buffer;
	$files{$file}{cont} .= substr($cont,$off+length($buffer),$len-$off-length($buffer)) if ($off+length($buffer) < $len);

	$files{$file}{size} = length($files{$file}{cont});

	if (! update_db($file)) {
		return -ENOSYS();
	} else {
		return length($buffer);
	}
}

sub e_truncate {
	my $file = filename_fixup(shift);
	my $size = shift;

	print "truncate to $size\n";

	$files{$file}{cont} = substr($files{$file}{cont},0,$size);
	$files{$file}{size} = $size;
	return 0
};


sub e_utime {
	my ($atime,$mtime,$file) = @_;
	$file = filename_fixup($file);

	return -ENOENT() unless exists($files{$file});

	print "utime '$file' $atime $mtime\n";

	$files{$file}{time} = $mtime;
	return 0;
}

sub e_statfs {

	my $size = 0;
	my $inodes = 0;

	foreach my $f (keys %files) {
		if ($f !~ /(^|\/)\.\.?$/) {
			$size += $files{$f}{size} || 0;
			$inodes++;
		}
		print "$inodes: $f [$size]\n";
	}

	$size = int(($size+BLOCK-1)/BLOCK);

	my @ret = (255, $inodes, 1, $size, $size-1, BLOCK);

	#print "statfs: ",join(",",@ret),"\n";

	return @ret;
}

sub e_unlink {
	my $file = filename_fixup(shift);

#	if (exists( $dirs{$file} )) {
#		print "unlink '$file' will re-read template names\n";
#		print Dumper($fuse_self);
#		$$fuse_self->{'read_filenames'}->();
#		return 0;
	if (exists( $files{$file} )) {
		print "unlink '$file' will invalidate cache\n";
		read_content($file,$files{$file}{id});
		return 0;
	}

	return -ENOENT();
}
1;
__END__

=head1 EXPORT

Nothing.

=head1 BUGS

Size information (C<ls -s>) is wrong. It's a problem in upstream Fuse module
(for which I'm to blame lately), so when it gets fixes, C<Fuse::DBI> will
automagically pick it up.

=head1 SEE ALSO

C<FUSE (Filesystem in USErspace)> website
L<http://fuse.sourceforge.net/>

Example for WebGUI which comes with this distribution in
directory C<examples/webgui.pl>. It also contains a lot of documentation
about design of this module, usage and limitations.

=head1 AUTHOR

Dobrica Pavlinusic, E<lt>dpavlin@rot13.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Dobrica Pavlinusic

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut

