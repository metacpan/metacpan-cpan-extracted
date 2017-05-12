#!/usr/bin/perl
# ABSTRACT: ACID transactions on a directory tree

package Directory::Transactional;
BEGIN {
  $Directory::Transactional::VERSION = '0.09';
}
use Moose;

use Time::HiRes qw(alarm);

use Set::Object;

use Carp;
use Fcntl qw(LOCK_EX LOCK_SH LOCK_NB);

use File::Spec;
use File::Find qw(find);
use File::Path qw(make_path remove_tree);
use File::Copy;
use IO::Dir;

use Directory::Transactional::TXN::Root;
use Directory::Transactional::TXN::Nested;
#use Directory::Transactional::Stream; # we require it later, it wants real Moose

use Try::Tiny;

use namespace::clean -except => 'meta';

has root => (
	is  => "ro",
	required => 1,
);

has _fatal => (
	isa => "Bool",
	is  => "rw",
);

has [qw(_root _work _backups _txns _locks _dirty _dirty_lock)] => (
	isa => "Str",
	is  => "ro",
	lazy_build => 1,
);

sub _build__root    { my $self = shift; blessed($self->root) ? $self->root->stringify : $self->root }
sub _build__work    { File::Spec->catdir(shift->_root, ".txn_work_dir") } # top level for all temp files
sub _build__txns    { File::Spec->catdir(shift->_work, "txns") } # one subdir per transaction, used for temporary files when transactions are active
sub _build__backups { File::Spec->catdir(shift->_work, "backups") } # one subdir per transaction, used during commit to root
sub _build__locks   { File::Spec->catdir(shift->_work, "locks") } # shared between all workers, directory for lockfiles
sub _build__dirty   { File::Spec->catfile(shift->_work, "dirty") }
sub _build__dirty_lock { shift->_dirty . ".lock" }

has nfs => (
	isa => "Bool",
	is  => "ro",
	default => 0,
);

has global_lock => (
	isa => "Bool",
	is  => "ro",
	lazy => 1,
	default => sub { shift->nfs },
);

has auto_commit => (
	isa => "Bool",
	is  => "ro",
	default => 1,
);

has crash_detection => (
	isa => "Bool",
	is  => "ro",
	default => 1,
);

has timeout => (
	isa => "Num",
	is  => "ro",
	predicate => "has_timeout",
);

sub _get_lock {
	my ( $self, @args ) = @_;

	return $self->nfs ? $self->_get_nfslock(@args) : $self->_get_flock(@args);
}

# slow, portable locking
# relies on atomic link()
# on OSX the stress test gets race conditions
sub _get_nfslock {
	my ( $self, $file, $mode ) = @_;

	# create the parent directory for the lock if necessary
	# (the lock dir is cleaned on destruction)
	my ( $vol, $dir ) = File::Spec->splitpath($file);
	my $parent = File::Spec->catpath($vol, $dir, '');
	make_path($parent) unless -d $parent;

	require File::NFSLock;
	if ( my $lock = File::NFSLock->new({
			file      => $file,
			lock_type => $mode,
			( $self->has_timeout ? ( blocking_timeout => $self->timeout ) : () ),
		}) ) {
		return $lock;
	} elsif ( not($mode & LOCK_NB) ) {
		no warnings 'once';
		die $File::NFSLock::errstr;
	}

	return;
}

# much faster locking, doesn't work on NFS though
sub _get_flock {
	my ( $self, $file, $mode ) = @_;

	# create the parent directory for the lock if necessary
	# (the lock dir is cleaned on destruction)
	my ( $vol, $dir ) = File::Spec->splitpath($file);
	my $parent = File::Spec->catpath($vol, $dir, '');
	make_path($parent) unless -d $parent;

	# open the lockfile, creating if necessary
	open my $fh, "+>", $file or die $!;

	my $ret;

	if ( not($mode & LOCK_NB) and $self->has_timeout ) {
		local $SIG{ALRM} = sub { croak "Lock timed out" };
		alarm($self->timeout);
		$ret = flock($fh, $mode);
		alarm(0);
	} else {
		$ret = flock($fh, $mode);
	}

	if ( $ret ) {
		my $class = ($mode & LOCK_EX) ? "Directory::Transactional::Lock::Exclusive" : "Directory::Transactional::Lock::Shared";
		return bless $fh, $class;
	} elsif ( $!{EWOULDBLOCK} or $!{EAGAIN} ) {
		# LOCK_NB failed
		return;
	} else {
		# die on any error except failing to obtain a nonblocking lock
		die $!;
	}
}

# support methods for fine grained locking
{
	package Directory::Transactional::Lock;
BEGIN {
  $Directory::Transactional::Lock::VERSION = '0.09';
}

	sub unlock { close $_[0] }
	sub is_exclusive { 0 }
	sub is_shared { 0 }
	sub upgrade { }
	sub upgrade_nb { $_[0] }
	sub downgrade { }

	package Directory::Transactional::Lock::Exclusive;
BEGIN {
  $Directory::Transactional::Lock::Exclusive::VERSION = '0.09';
}
	use Fcntl qw(LOCK_SH);

	BEGIN { our @ISA = qw(Directory::Transactional::Lock) }

	sub is_exclusive { 1 }

	sub downgrade {
		my $self = shift;
		flock($self, LOCK_SH) or die $!;
		bless $self, "Directory::Transactional::Lock::Shared";
	}

	package Directory::Transactional::Lock::Shared;
BEGIN {
  $Directory::Transactional::Lock::Shared::VERSION = '0.09';
}
	use Fcntl qw(LOCK_EX LOCK_NB);

	BEGIN { our @ISA = qw(Directory::Transactional::Lock) }

	sub is_shared { 1 }
	sub upgrade {
		my $self = shift;
		flock($self, LOCK_EX) or die $!;
		bless($self, "Directory::Transactional::Lock::Exclusive");
	}

	sub upgrade_nb {
		my $self = shift;

		unless ( flock($self, LOCK_EX|LOCK_NB) ) {
			if ( $!{EWOULDBLOCK} ) {
				return;
			} else {
				die $!;
			}
		}

		bless($self, "Directory::Transactional::Lock::Exclusive");
	}
}

# this is the current active TXN (head of transaction stack)
has _txn => (
	isa => "Directory::Transactional::TXN",
	is  => "rw",
	clearer => "_clear_txn",
);

has _shared_lock_file => (
	isa => "Str",
	is  => "ro",
	lazy_build => 1,
);

sub _build__shared_lock_file { shift->_work . ".lock" }

has _shared_lock => (
	is  => "ro",
	lazy_build => 1,
);

# the shared lock is always taken at startup
# a nonblocking attempt to lock it exclusively is made first, and if granted we
# have exclusive access to the work directory so recovery is run if necessary
sub _build__shared_lock {
	my $self = shift;

	my $file = $self->_shared_lock_file;

	if ( my $ex_lock = $self->_get_lock( $file, LOCK_EX|LOCK_NB ) ) {
		$self->recover;

		undef $ex_lock;
	}

	$self->_get_lock($file, LOCK_SH);
}

sub BUILD {
	my $self = shift;

	croak "If 'nfs' is set then so must be 'global_lock'"
		if $self->nfs and !$self->global_lock;

	# obtains the shared lock, running recovery if needed
	$self->_shared_lock;

	make_path($self->_work);
}

sub DEMOLISH {
	my $self = shift;

	return if $self->_fatal; # encountered a fatal error, we need to run recovery

	# rollback any open txns
	while ( $self->_txn ) {
		$self->txn_rollback;
	}

	# lose the shared lock
	$self->_clear_shared_lock;

	# cleanup workdirs
	# only remove if no other workers are active, so that there is no race
	# condition in their directory creation code
	if ( my $ex_lock = $self->_get_lock( $self->_shared_lock_file, LOCK_EX|LOCK_NB ) ) {
		# we don't really care if there's an error
		try { local $SIG{__WARN__} = sub { }; remove_tree($self->_locks) };
		rmdir $self->_work;
		rmdir $self->_txns;
		rmdir $self->_backups;

		unlink $self->_dirty;
		unlink $self->_dirty_lock;

		rmdir $self->_work;

		CORE::unlink $self->_shared_lock_file;
	}
}

sub check_dirty {
	my $self = shift;

	return unless $self->crash_detection;

	# get the short lived dirty flag manipulation lock
	# nobody else can check or modify the dirty flag while we have it
	my $ex_lock = $self->_get_lock( $self->_dirty_lock, LOCK_EX );

	my $dirty = $self->_dirty;

	# if the dirty flag is set, run a check
	if ( -e $dirty ) {
		my $b = $self->_backups;

		# go through the comitting transactions
		foreach my $name ( IO::Dir->new($b)->read ) {
			next unless $name =~ /^[\w\-]+$/; # txn dir

			my $dir = File::Spec->catdir($b, $name);

			if ( my $ex_lock = $self->_get_lock( $dir . ".lock", LOCK_EX|LOCK_NB ) ) {
				# there is a potential race condition between the readdir
				# and getting the lock. make sure it still exists
				if ( -d $dir ) {
					$self->online_recover;
					return $ex_lock;
				}
			}
		}

		# the check passed, now we can clear the dirty flag if there are no
		# other running commits
		if ( my $flag_ex_lock = $self->_get_lock( $dirty, LOCK_EX|LOCK_NB ) ) {
			unlink $dirty;
		}
	}

	# return the lock.
	# for as long as it is held the workdir cannot be marked dirty except by
	# this process
	return $ex_lock;
}

sub set_dirty {
	my $self = shift;

	return unless $self->crash_detection;

	# first check that the dir is not dirty, and take an exclusive lock for
	# dirty flag manipulation
	my $ex_lock = $self->check_dirty;

	# next mark the dir as dirty, and take a shared lock so the flag won't be
	# cleared by check_dirty

	my $dirty_lock = $self->_get_lock( $self->_dirty, LOCK_SH );

	# create the file if necessary (nfs uses an auxillary lock file)
	open my $fh, ">", $self->_dirty or die $! if $self->nfs;

	return $dirty_lock;
}

sub recover {
	my $self = shift;

	# first rollback partially comitted transactions if there are any
	if ( -d ( my $b = $self->_backups ) ) {
		foreach my $name ( IO::Dir->new($b)->read ) {
			next if $name eq '.' || $name eq '..';

			my $txn_backup = File::Spec->catdir($b, $name); # each of these is one transaction

			if ( -d $txn_backup ) {
				my $files = $self->_get_file_list($txn_backup);

				# move all the backups back into the root directory
				$self->merge_overlay( from => $txn_backup, to => $self->_root, files => $files );

				remove_tree($txn_backup);
			}
		}

		remove_tree($b, { keep_root => 1 });
	}

	# delete all temp files (fully comitted but not cleaned up transactions,
	# and uncomitted transactions)
	if ( -d $self->_txns ) {
		remove_tree( $self->_txns, { keep_root => 1 } );
	}

	unlink $self->_dirty;
	unlink $self->_dirty_lock;
}

sub online_recover {
	my $self = shift;

	unless ( $self->nfs ) { # can't upgrade an nfs lock
		my $lock = $self->_shared_lock;

		if ( $lock->upgrade_nb ) {
			$self->recover;
			$lock->downgrade;
			return 1;
		}
	}

	$self->_fatal(1);
	croak "Detected crashed transaction, terminate all processes and run recovery by reinstantiating directory";
}

sub _get_file_list {
	my ( $self, $from ) = @_;

	my $files = Set::Object->new;

	find( { no_chdir => 1, wanted   => sub { $files->insert( File::Spec->abs2rel($_, $from) ) if -f $_ } }, $from );

	return $files;
}

sub merge_overlay {
	my ( $self, %args ) = @_;

	my ( $from, $to, $backup, $files ) = @args{qw(from to backup files)};

	my @rem;

	# if requested, back up first by moving all the files from the target
	# directory to the backup directory
	if ( $backup ) {
		foreach my $file ( $files->members ) {
			my $src = File::Spec->catfile($to, $file);

			next unless -e $src; # there is no source file to back

			my $targ = File::Spec->catfile($backup, $file);

			# create the parent directory in the backup dir as necessary
			my ( undef, $dir ) = File::Spec->splitpath($targ);
			if ( $dir ) {
				make_path($dir) unless -d $dir;
			}

			CORE::rename $src, $targ or die $!;
		}
	}

	# then apply all the changes to the target dir from the source dir
	foreach my $file ( $files->members ) {
		my $src = File::Spec->catfile($from,$file);

		if ( -f $src ) {
			my $targ = File::Spec->catfile($to,$file);

			# make sure the parent directory in the target path exists first
			my ( undef, $dir ) = File::Spec->splitpath($targ);
			if ( $dir ) {
				make_path($dir) unless -d $dir;
			}

			if ( -f $src ) {
				CORE::rename $src => $targ or die $!;
			} elsif ( -f $targ ) {
				CORE::unlink $targ or die $!;
			}
		}
	}
}

sub txn_do {
	my ( $self, @args ) = @_;

	unshift @args, "body" if @args % 2;

	my %args = @args;

	my ( $coderef, $commit, $rollback, $code_args ) = @args{qw(body commit rollback args)};

	ref $coderef eq 'CODE' or croak '$coderef must be a CODE reference';

	$code_args ||= [];

	$self->txn_begin;

	my @result;

	my $wantarray = wantarray; # gotta capture, eval { } has its own

	my ( $success, $err ) = do {
		local $@;

		my $success = eval {
			if ( $wantarray ) {
				@result = $coderef->(@$code_args);
			} elsif( defined $wantarray ) {
				$result[0] = $coderef->(@$code_args);
			} else {
				$coderef->(@$code_args);
			}

			$commit && $commit->();
			$self->txn_commit;

			1;
		};

		( $success, $@ );
	};

	if ( $success ) {
		return wantarray ? @result : $result[0];
	} else {
		my $rollback_exception = do {
			local $@;
			eval { $self->txn_rollback; $rollback && $rollback->() };
			$@;
		};

		if ($rollback_exception) {
			croak "Transaction aborted: $err, rollback failed: $rollback_exception";
		}

		die $err;
	}
}

sub txn_begin {
	my ( $self, @args ) = @_;

	my $txn;

	if ( my $p = $self->_txn ) {
		# this is a child transaction

		croak "Can't txn_begin if an auto transaction is still alive" if $p->auto_handle;

		$txn = Directory::Transactional::TXN::Nested->new(
			parent  => $p,
			manager => $self,
		);
	} else {
		# this is a top level transaction
		$txn = Directory::Transactional::TXN::Root->new(
			@args,
			manager => $self,
			( $self->global_lock ? (
				# when global_lock is set, take an exclusive lock on the root dir
				# non global lockers take a shared lock on it
				global_lock => $self->_get_flock( File::Spec->catfile( $self->_locks, ".lock" ), LOCK_EX)
			) : () ),
		);
	}

	$self->_txn($txn);

	return;
}

sub _pop_txn {
	my $self = shift;

	my $txn = $self->_txn or croak "No active transaction";

	if ( $txn->isa("Directory::Transactional::TXN::Nested") ) {
		$self->_txn( $txn->parent );
	} else {
		$self->_clear_txn;
	}

	return $txn;
}

sub txn_commit {
	my $self = shift;

	my $txn = $self->_txn;

	my $changed = $txn->changed;

	if ( $changed->size ) {
		if ( $txn->isa("Directory::Transactional::TXN::Root") ) {
			# commit the work, backing up in the backup dir

			# first take a lock on the backup dir
			# this is used to detect crashed transactions
			# if the dir exists but isn't locked then the transaction crashed
			my $txn_lockfile = $txn->backup . ".lock";
			my $txn_lock = $self->_get_lock( $txn_lockfile, LOCK_EX );

			{
				# during a commit the work dir is considered dirty
				# this flag is set until check_dirty clears it
				my $dirty_lock = $self->set_dirty;

				$txn->create_backup_dir;

				# move all the files from the txn dir into the root dir, using the backup dir
				$self->merge_overlay( from => $txn->work, to => $self->_root, backup => $txn->backup, files => $changed );

				# we're finished, remove backup dir denoting successful commit
				CORE::rename $txn->backup, $txn->work . ".cleanup" or die $!;
			}

			unlink $txn_lockfile;
		} else {
			# it's a nested transaction, which means we don't need to be
			# careful about comitting to the parent, just share all the locks,
			# deletion metadata etc by merging it
			$txn->propagate;

			$self->merge_overlay( from => $txn->work, to => $txn->parent->work, files => $changed );
		}

		# clean up work dir and (renamed) backup dir
		remove_tree( $txn->work );
		remove_tree( $txn->work . ".cleanup" );
	}

	$self->_pop_txn;

	return;
}

sub txn_rollback {
	my $self = shift;

	my $txn = $self->_pop_txn;

	if ( $txn->isa("Directory::Transactional::TXN::Root") ) {
		# an error happenned during txn_commit trigerring a rollback
		if ( -d ( my $txn_backup = $txn->backup ) ) {
			my $files = $self->_get_file_list($txn_backup);

			# move all the backups back into the root directory
			$self->merge_overlay( from => $txn_backup, to => $self->_root, files => $files );
		}
	} else {
		# any inherited locks that have been upgraded in this txn need to be
		# downgraded back to shared locks
		foreach my $lock ( @{ $txn->downgrade } ) {
			$lock->downgrade;
		}
	}

	# now all we need to do is trash the tempfiles and we're done
	if ( $txn->has_work ) {
		remove_tree( $txn->work );
	}

	return;
}

sub _auto_txn {
	my $self = shift;

	return if $self->_txn;

	croak "Auto commit is disabled" unless $self->auto_commit;

	require Scope::Guard;

	$self->txn_begin;

	return Scope::Guard->new(sub { $self->txn_commit });
}

sub _resource_auto_txn {
	my $self = shift;

	if ( my $txn = $self->_txn ) {
		# return the same handle so that more resources can be registered
		return $txn->auto_handle;
	} else {
		croak "Auto commit is disabled" unless $self->auto_commit;

		require Directory::Transactional::AutoCommit;

		my $h = Directory::Transactional::AutoCommit->new( manager => $self );

		$self->txn_begin( auto_handle => $h );

		return $h;
	}
}

sub _lock_path_read {
	my ( $self, $path ) = @_;

	my $txn = $self->_txn;

	if ( my $lock = $txn->find_lock($path) ) {
		return $lock;
	} else {
		my $lock = $self->_get_flock( File::Spec->catfile( $self->_locks, $path . ".lock" ), LOCK_SH);
		$txn->set_lock( $path, $lock );
	}
}

sub _lock_path_write {
	my ( $self, $path ) = @_;

	my $txn = $self->_txn;

	if ( my $lock = $txn->get_lock($path) ) {
		# simplest scenario, we already have a lock in this transaction
		$lock->upgrade; # upgrade it if necessary
	} elsif ( my $inherited_lock = $txn->find_lock($path) ) {
		# a parent transaction has a lock
		unless ( $inherited_lock->is_exclusive ) {
			# upgrade it, and mark for downgrade on rollback
			$inherited_lock->upgrade;
			push @{ $txn->downgrade }, $inherited_lock;
		}
		$txn->set_lock( $path, $inherited_lock );
	} else {
		# otherwise create a new lock
		my $lock = $self->_get_flock( File::Spec->catfile( $self->_locks, $path . ".lock" ), LOCK_EX);
		$txn->set_lock( $path, $lock );
	}
}

sub _lock_parent {
	my ( $self, $path ) = @_;

	my ( undef, $dir ) = File::Spec->splitpath($path);

	my @dirs = File::Spec->splitdir($dir);

	{
		no warnings 'uninitialized';
		pop @dirs unless length $dirs[-1]; # trailing slash
	}
	pop @dirs if $dir eq $path;

	my $parent = "";

	do {
		$self->_lock_path_read($parent);
	} while (
		@dirs
			and
		$parent = length($parent)
			? File::Spec->catdir($parent, shift @dirs)
			: shift @dirs
	);

	return;
}

# lock a path for reading
sub lock_path_read {
	my ( $self, $path ) = @_;

	unless ( $self->_txn ) {
		croak("Can't lock file for reading without an active transaction");
	}

	return if $self->global_lock;

	$self->_lock_parent($path);

	$self->_lock_path_read($path);

	return;
}

sub lock_path_write {
	my ( $self, $path ) = @_;

	unless ( $self->_txn ) {
		croak("Can't lock file for writing without an active transaction");
	}

	return if $self->global_lock;

	$self->_lock_parent($path);

	$self->_lock_path_write($path);

	return;
}

sub _txn_stack {
	my $self = shift;

	if ( my $txn = $self->_txn ) {
		my @ret = $txn;
		push @ret, $txn = $txn->parent while $txn->can("parent");
		return @ret;
	}

	return;
}

sub _txn_for_path {
	my ( $self, $path ) = @_;

	if ( my $txn = $self->_txn ) {
		do {
			if ( $txn->is_changed_in_head($path) ) {
				return $txn;
			};
		} while ( $txn->can("parent") and $txn = $txn->parent );
	}

	return;
}

sub _locate_dirs_in_overlays {
	my ( $self, $path ) = @_;

	my @dirs = ( (map { $_->work } $self->_txn_stack), $self->root );

	if ( defined $path ) {
		return grep { -d $_ } map { File::Spec->catdir($_, $path) } @dirs;
	} else {
		return @dirs;
	}
}

sub _locate_file_in_overlays {
	my ( $self, $path ) = @_;

	if ( my $txn = $self->_txn_for_path($path) ) {
		File::Spec->catfile($txn->work, $path);
	} else {
		#unless ( $self->_txn->find_lock($path) ) { # can't optimize this way if an explicit lock was taken
			# we only take a read lock on the root dir if the state isn't dirty
			my $ex_lock = $self->check_dirty;
			$self->lock_path_read($path);
		#}
		File::Spec->catfile($self->_root, $path);
	}
}

sub old_stat {
	my ( $self, $path ) = @_;

	my $t = $self->_auto_txn;

	CORE::stat($self->_locate_file_in_overlays($path));
}

sub stat {
	my ( $self, $path ) = @_;

	my $t = $self->_auto_txn;

	require File::stat;
	File::stat::stat($self->_locate_file_in_overlays($path));
}

sub is_deleted {
	my ( $self, $path ) = @_;

	not $self->exists($path);
}

sub exists {
	my ( $self, $path ) = @_;

	my $t = $self->_auto_txn;

	return -e $self->_locate_file_in_overlays($path);
}

sub is_dir {
	my ( $self, $path ) = @_;

	my $t = $self->_auto_txn;

	# FIXME this is an ugly kludge, we really need to keep better track of
	# why/when directories are created, make note of them in 'is_changed', etc.

	my @dirs = ( (map { $_->work } $self->_txn_stack), $self->root );

	foreach my $dir ( @dirs ) {
		return 1 if -d File::Spec->catdir($dir, $path);
	}

	return;
}

sub is_file {
	my ( $self, $path ) = @_;

	my $t = $self->_auto_txn;

	return -f $self->_locate_file_in_overlays($path);
}

sub unlink {
	my ( $self, $path ) = @_;

	my $t = $self->_auto_txn;

	# lock parent for writing
	my ( undef, $dir ) = File::Spec->splitpath($path);
	$self->lock_path_write($dir);

	my $txn_file = $self->_work_path($path);

	if ( -e $txn_file ) {
		CORE::unlink $txn_file or die $!;
	} else {
		return 1;
	}
}

sub rename {
	my ( $self, $from, $to ) = @_;

	my $t = $self->_auto_txn;

	foreach my $path ( $from, $to ) {
		# lock parents for writing
		my ( undef, $dir ) = File::Spec->splitpath($path);
		$self->lock_path_write($dir);
	}

	$self->vivify_path($from),

	CORE::rename (
		$self->_work_path($from),
		$self->_work_path($to),
	) or die $!;
}

sub openr {
	my ( $self, $file ) = @_;

	my $t = $self->_resource_auto_txn;

	my $src = $self->_locate_file_in_overlays($file);

	open my $fh, "<", $src or die "openr($file): $!";

	$t->register($fh) if $t;

	return $fh;
}

sub openw {
	my ( $self, $path ) = @_;

	my $t = $self->_resource_auto_txn;

	my $txn = $self->_txn;

	my $file = File::Spec->catfile( $txn->work, $path );

	unless ( $txn->is_changed_in_head($path) ) {
		my ( undef, $dir ) = File::Spec->splitpath($path);

		$self->lock_path_write($path);

		make_path( File::Spec->catdir($txn->work, $dir) ) if length($dir); # FIXME only if it exists in the original?
	}

	$txn->mark_changed($path);

	open my $fh, ">", $file or die "openw($path): $!";

	$t->register($fh) if $t;

	return $fh;
}

sub opena {
	my ( $self, $file ) = @_;

	my $t = $self->_resource_auto_txn;

	$self->vivify_path($file);

	open my $fh, ">>", $self->_work_path($file) or die "opena($file): $!";

	$t->register($fh) if $t;

	return $fh;
}

sub open {
	my ( $self, $mode, $file ) = @_;

	my $t = $self->_resource_auto_txn;

	$self->vivify_path($file);

	open my $fh, $mode, $self->_work_path($file) or die "open($mode, $file): $!";

	$t->register($fh) if $t;

	return $fh;
}

sub _readdir_from_overlay {
	my ( $self, $path ) = @_;

	my $t = $self->_auto_txn;

	my $ex_lock = $self->check_dirty;

	my @dirs = $self->_locate_dirs_in_overlays($path);

	my $files = Set::Object->new;

	# compute union of all directories
	foreach my $dir ( @dirs ) {
		$files->insert( IO::Dir->new($dir)->read );
	}

	unless ( defined $path ) {
		$files->remove(".txn_work_dir");
		$files->remove(".txn_work_dir.lock");
		$files->remove(".txn_work_dir.lock.NFSLock") if $self->nfs;
	}

	return $files;
}

sub readdir {
	my ( $self, $path ) = @_;

	undef $path if $path eq "/" or !length($path);

	my $t = $self->_auto_txn;

	my $files = $self->_readdir_from_overlay($path);

	my @txns = $self->_txn_stack;

	# remove deleted files
	file: foreach my $file ( $files->members ) {
		next if $file eq '.' or $file eq '..';

		my $file_path = $path ? File::Spec->catfile($path, $file) : $file;

		foreach my $txn ( @txns ) {
			if ( $txn->is_changed_in_head($file_path) ) {
				if ( not( -e File::Spec->catfile( $txn->work, $file_path ) ) ) {
					$files->remove($file);
				}
				next file;
			}
		}
	}

	return $files->members;
}

sub list {
	my ( $self, $path ) = @_;

	undef $path if $path eq "/" or !length($path);

	my $t = $self->_auto_txn;

	my $files = $self->_readdir_from_overlay($path);

	$files->remove('.', '..');

	my @txns = $self->_txn_stack;

	my @ret;

	# remove deleted files
	file: foreach my $file ( $files->members ) {
		my $file_path = $path ? File::Spec->catfile($path, $file) : $file;

		foreach my $txn ( @txns ) {
			if ( $txn->is_changed_in_head($file_path) ) {
				if ( -e File::Spec->catfile( $txn->work, $file_path ) ) {
					push @ret, $file_path;
				}
				next file;
			}
		}

		push @ret, $file_path;
	}

	return sort @ret;
}

sub _work_path {
	my ( $self, $path ) = @_;

	$self->lock_path_write($path);

	my $txn = $self->_txn;

	$txn->mark_changed($path);

	my $file = File::Spec->catfile( $txn->work, $path );

	my ( undef, $dir ) = File::Spec->splitpath($path);
	make_path( File::Spec->catdir($txn->work, $dir ) ) if length($dir); # FIXME only if it exists in the original?

	return $file;
}

sub vivify_path {
	my ( $self, $path ) = @_;

	my $txn = $self->_txn;

	my $txn_path = File::Spec->catfile( $txn->work, $path );

	unless ( $txn->is_changed_in_head($path) ) {
		$self->lock_path_write($path);

		my $src = $self->_locate_file_in_overlays($path);

		if ( my $stat = File::stat::stat($src) ) {
			if ( $stat->nlink > 1 ) {
				croak "the file $src has a link count of more than one.";
			}

			if ( -l $src ) {
				croak "The file $src is a symbolic link.";
			}

			$self->_work_path($path); # FIXME vivifies parent dir
			copy( $src, $txn_path ) or die "copy($src, $txn_path): $!";
		}
	}

	return $txn_path;
}



sub file_stream {
	my ( $self, @args ) = @_;

	my $t = $self->_resource_auto_txn;

	require Directory::Transactional::Stream;

	my $stream = Directory::Transactional::Stream->new(
		manager => $self,
		@args,
	);

	$t->register($stream) if $t;

	return $stream;
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 NAME


=head1 VERSION

version 0.09
Directory::Transactional - ACID transactions on a set of files with
journalling/recovery using C<flock> or L<File::NFSLock>

=head1 SYNOPSIS

	use Directory::Transactional;

	my $d = Directory::Transactional->new( root => $path );

	$d->txn_do(sub {
		my $fh = $d->openw("path/to/file");

		$fh->print("I AR MODIFY");

		close $fh;
	});

=head1 DESCRIPTION

This module provides lock based transactions over a set of files with full
supported for nested transactions.

=head1 THE RULES

There are a few limitations to what this module can do.

Following this guideline will prevent unpleasant encounters:

=over 4

=item Always use relative paths

No attempt is made to sanify paths reaching outside of the root.

All paths are assumed to be relative and within the root.

=item No funny stuff

Stick with plain files, with a link count of 1, or you will not get what you
expect.

For instance a rename will first copy the source file to the txn work dir, and
then when comitting rename that file to the target dir and unlink the original.

While seemingly more work, this is the only way to ensure that modifications to
the file both before and after the rename are consistent.

Modifications to directories are likewise not supported, but support may be
added in the future.

=item Always work in a transaction

If you don't need transaction, use a global lock file and don't use this
module.

If you do, then make sure even your read access goes through this object with
an active transaction, or you may risk reading uncomitted data, or conflicting
with the transaction commit code.

=item Use C<global_lock> or make sure you lock right

If you stick to modifying the files through the API then you shouldn't have
issues with locking, but try not to reuse paths and always reask for them to
ensure that the right "real" path is returned even if the transaction stack has
changed, or anything else.

=item No forking

If you fork in the middle of the transaction both the parent and the child have
write locks, and both the parent and the child will try to commit or rollback
when resources are being cleaned up.

Either create the L<Directory::Transactional> instance within the child
process, or use L<POSIX/_exit> and do not open or close any transactions in the
child.

=item No mixing of C<nfs> and C<flock>

C<nfs> mode is not compatible with C<flock> mode. If you enable C<nfs> enable
it in B<all> processes working on the same directory.

Conversely, under C<flock> mode C<global_lock> B<is> compatible with fine
grained locking.

=back

=head1 ACID GUARANTEES

ACID stands for atomicity, consistency, isolation and durability.

Transactions are atomic (using locks), consistent (a recovery mode is able to
restore the state of the directory if a process crashed while comitting a
transaction), isolated (each transaction works in its own temporary directory),
and durable (once C<txn_commit> returns a software crash will not cause the
transaction to rollback).

=head1 TRANSACTIONAL PROTOCOL

This section describes the way the ACID guarantees are met:

When the object is being constructed a nonblocking attempt to get an exclusive
lock on the global shared lock file using L<File::NFSLock> or C<flock> is made.

If this lock is successful this means that this object is the only active
instance, and no other instance can access the directory for now.

The work directory's state is inspected, any partially comitted transactions
are rolled back, and all work files are cleaned up, producing a consistent
state.

At this point the exclusive lock is dropped, and a shared lock on the same file
is taken, which will be retained for the lifetime of the object.

Each transaction (root or nested) gets its own work directory, which is an
overlay of its parent.

All write operations are performed in the work directory, while read operations
walk up the tree.

Aborting a transaction consists of simply removing its work directory.

Comitting a nested transaction involves overwriting its parent's work directory
with all the changes in the child transaction's work directory.

Comitting a root transaction to the root directory involves moving aside every
file from the root to a backup directory, then applying the changes in the work
directory to the root, renaming the backup directory to a work directory, and
then cleaning up the work directory and the renamed backup directory.

If at any point in the root transaction commit work is interrupted, the backup
directory acts like a journal entry. Recovery will rollback this transaction by
restoring all the renamed backup files. Moving the backup directory into the
work directory signifies that the transaction has comitted successfully, and
recovery will clean these files up normally.

If C<crash_detection> is enabled (the default) when reading any file from the
root directory (shared global state) the system will first check for crashed
commits.

Crashed commits are detected by means of lock files. If the backup directory is
locked that means its comitting process is still alive, but if a directory
exists without a lock then that process has crashed. A global dirty flag is
maintained to avoid needing to check all the backup directories each time.

If the commit is still running then it can be assumed that the process
comitting it still has all of its exclusive locks so reading from the root
directory is safe.

=head1 DEADLOCKS

This module does not implement deadlock detection. Unfortunately maintaing a
lock table is a delicate and difficult task, so I doubt I will ever implement
it.

The good news is that certain operating systems (like HPUX) may implement
deadlock detection in the kernel, and return C<EDEADLK> instead of just
blocking forever.

If you are not so lucky, specify a C<timeout> or make sure you always take
locks in the same order.

The C<global_lock> flag can also be used to prevent deadlocks entirely, at the
cost of concurrency. This provides fully serializable level transaction
isolation with no possibility of serialization failures due to deadlocks.

There is no pessimistic locking mode (read-modify-write optimized) since all
paths leading to a file are locked for reading. This mode, if implemented,
would be semantically identical to C<global_lock> but far less efficient.

In the future C<fcntl> based locking may be implemented in addition to
C<flock>. C<EDEADLK> seems to be more widely supported when using C<fcntl>.

=head1 LIMITATIONS

=head2 Auto-Commit

If you perform any operation outside of a transaction and C<auto_commit> is
enabled a transaction will be created for you.

For operations like C<rename> or C<readdir> which do not return resource the
transaction is comitted immediately.

Operations like C<open> or C<file_stream> on the other create a transaction
that will be alive as long as the return value is alive.

This means that you should not leak filehandles when relying on autocommit.

Opening a new transaction when an automatic one is already opened is an error.

Note that this resource tracking comes with an overhead, especially on Perl
5.8, so even if you are only performing read operations it is reccomended that
you operate within the scope of a real transaction.

=head2 Open Filehandles

One filehandle is required per every lock when using fine grained locking.

For large transactions it is reccomended you set C<global_lock>, which is like
taking an exclusive lock on the root directory.

C<global_lock> also performs better, but causes long wait times if multiple
processes are accessing the same database but not the same data. For web
applications C<global_lock> should probably be off for better concurrency.

=head1 ATTRIBUTES

=over 4

=item root

This is the managed directory in which transactional semantics will be maintained.

This can be either a string path or a L<Path::Class::Dir>.

=item _work

This attribute is named with a leading underscore to prevent thoughtless
modification (if you have two workers accessing the same directory
simultaneously but the work dir is different they will conflict and not even
know it).

The default work directory is placed under root, and is named C<.txn_work_dir>.

The work dir's parent must be writable, because a lock file needs to be created
next to it (the workdir name with C<.lock> appended).

=item nfs

If true (defaults to false), L<File::NFSLock> will be used for all locks
instead of C<flock>.

Note that on my machine the stress test reliably B<FAILS> with
L<File::NFSLock>, due to a race condition (exclusive write lock granted to two
writers simultaneously), even on a local filesystem. If you specify the C<nfs>
flag make sure your C<link> system call is truly atomic.

=item global_lock

If true instead of using fine grained locking, a global write lock is obtained
on the first call to C<txn_begin> and will be kept for as long as there is a
running transaction.

This is useful for avoiding deadlocks (there is no deadlock detection code in
the fine grained locking).

This flag is automatically set if C<nfs> is set.

=item timeout

If set will be used to specify a time limit for blocking calls to lock.

If you are experiencing deadlocks it is reccomended to set this or
C<global_lock>.

=item auto_commit

If true (the default) any operation not performed within a transaction will
cause a transaction to be automatically created and comitted.

Transactions automatically created for operations which return things like
filehandles will stay alive for as long as the returned resource does.

=item crash_detection

IF true (the default), all read operations accessing global state (the root
directory) will first ensure that the global directory is not dirty.

If the perl process crashes while comitting the transaction but other
concurrent processes are still alive, the directory is left in an inconsistent
state, but all the locks are dropped. When C<crash_detection> is enabled ACID
semantics are still guaranteed, at the cost of locking and stating a file for
each read operation on the global directory.

If you disable this then you are only protected from system crashes (recovery
will be run on the next instantiation of L<Directory::Transactional>) or soft
crashes where the crashing process has a chance to run all its destructors
properly.

=back

=head1 METHODS

=head2 Transaction Management

=over 4

=item txn_do $code, %callbacks

Executes C<$code> within a transaction in an C<eval> block.

If any error is thrown the transaction will be rolled back. Otherwise the
transaction is comitted.

C<%callbacks> can contain entries for C<commit> and C<rollback>, which are
called when the appropriate action is taken.

=item txn_begin

Begin a new transaction. Can be called even if there is already a running
transaction (nested transactions are supported).

=item txn_commit

Commit the current transaction. If it is a nested transaction, it will commit
to the parent transaction's work directory.

=item txn_rollback

Discard the current transaction, throwing away all changes since the last call
to C<txn_begin>.

=back

=head2 Lock Management

=over 4

=item lock_path_read $path, $no_parent

=item lock_path_write $path, $no_parent

Lock the resource at C<$path> for writing or reading.

By default the ancestors of C<$path> will be locked for reading to (from
outermost to innermost).

The only way to unlock a resource is by comitting the root transaction, or
aborting the transaction in which the resource was locked.

C<$path> does not have to be a real file in the C<root> directory, it is
possible to use symbolic names in order to avoid deadlocks.

Note that these methods are no-ops if C<global_lock> is set.

=back

=head2 File Access

=over 4

=item openr $path

=item openw $path

=item opena $path

=item open $mode, $path

Open a file for reading, writing (clobbers) or appending, or with a custom mode
for three arg open.

Using C<openw> or C<openr> is reccomended if that's all you need, because it
will not copy the file into the transaction work dir first.

=item stat $path

Runs L<File::stat/stat> on the physical path.

=item old_stat $path

Runs C<CORE::stat> on the physical path.

=item exists $path

=item is_deleted $path

Whether a file exists or has been deleted in the current transaction.

=item is_file $path

Runs the C<-f> file test on the right physical path.

=item is_dir $path

Runs the C<-d> file test on the right physical path.

=item unlink $path

Deletes the file in the current transaction

=item rename $from, $to

Renames the file in the current transaction.

Note that while this is a real C<rename> call in the txn work dir that is done
on a copy, when comitting to the top level directory the original will be
unlinked and the new file from the txn work dir will be renamed to the original.

Hard links will B<NOT> be retained.

=item readdir $path

Merges the overlays of all the transactions and returns unsorted basenames.

A path of C<""> can be used to list the root directory.

=item list $path

A DWIM version of C<readdir> that returns paths relative to C<root>, filters
out C<.> and C<..> and sorts the output.

A path of C<""> can be used to list the root directory.

=item file_stream %args

Creates a L<Directory::Transactional::Stream> for a recursive file listing.

The C<dir> option can be used to specify a directory, defaulting to C<root>.

=back

=head2 Internal Methods

These are documented so that they may provide insight into the inner workings
of the module, but should not be considered part of the API.

=over 4

=item merge_overlay

Merges one directory over another.

=item recover

Runs the directory state recovery code.

See L</"TRANSACTIONAL PROTOCOL">

=item online_recover

Called to recover when the directory is already instantiated, by C<check_dirty>
if a dirty state was found.

=item check_dirty

Check for transactions that crashed in mid commit

=item set_dirty

Called just before starting a commit.

=item vivify_path $path

Copies C<$path> as necessary from a parent transaction or the root directory in
order to facilitate local work.

Does not support hard or symbolic links (yet).

=back

=cut