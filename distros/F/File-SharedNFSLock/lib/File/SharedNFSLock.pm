package File::SharedNFSLock;
use 5.008001;
use strict;
use warnings;
use File::Spec;
use Sys::Hostname ();
use Time::HiRes ();
use Carp 'croak';

use constant STAT_NLINKS => 3;
use constant DEBUG => 0;

our $VERSION = '0.04';

=head1 NAME

File::SharedNFSLock - Inter-machine advisory file locking on NFS volumes

=head1 SYNOPSIS

  use File::SharedNFSLock;
  my $flock = File::SharedNFSLock->new(
    file => 'some_file_on_nfs',
  );
  my $got_lock = $flock->lock(); # blocks for $timeout_acquire seconds if necessary
  if ($got_lock) {
    # hack hack hack...
  }
  $flock->unlock;
  
  # meanwhile, on another machine or in another process:
  my $flock = File::SharedNFSLock->new(
    file => 'some_file_on_nfs',
  );
  my $got_lock = $flock->lock(); # blocks for timeout or until first process is done
  # ...

=head1 DESCRIPTION

This module implements advisory file locking on NFS (or non-NFS) filesystems.

NFS (at least before v4) is evil. File locking on NFS volumes is worse. This
module attempts to implement file locking on NFS volumes using lock files and
hard links. It's in production use at our site, but if it doesn't work for you,
I'm not surprised!

Note that the lock files are always written to the same directory as the original
file! There is always one lock file per process that tries to acquire the lock.
This module does B<NOT> do signal handling. You will have to do that yourself.

=head2 ALGORITHM

I use the fact that hard links are (err, appear to be) atomic even with NFS.
So I write a process-specific, unique lock file and then hard-link it to the
real thing. Afterwards, C<stat()> tells me the number of hard-linked instances
of the file (when polling my unique, private file). This indicates that I
have acquired the lock.

The algorithm was snatched from a document called I<NFS Considered Harmful> by
I<Shane Kerr>. I found it at L<http://www.time-travellers.org/shane/papers/NFS_considered_harmful.html>.
Look for chapter III, I<List of Concerns>, concern I<d>: I<Exclusive File Creation>.
The described workaround is, I quote:

  The solution for performing atomic file locking using a lockfile
  is to create a unique file on the same fs (e.g., incorporating
  hostname and pid), use link(2) to make a link to the lockfile and
  use stat(2) on the unique file to check if its link count has
  increased to 2. Do not use the return value of the link() call.

=head1 METHODS

=head2 new

Creates a new lock object but does B<NOT> attempt to acquire
the lock (see C<lock()> below). Takes named arguments.
All times in the parameters are in seconds and can
be floating point values, indicating a fraction of a second.

Mandatory argument: I<file> pointing at the file that
is to be locked.

Optional arguments: I<poll_interval> indicates
the number of seconds to wait between attempts to
acquire the lock. Defaults to 1 second.

I<timeout_acquire> indicates the total
time that may be spent trying to acquire a lock when
C<lock()> is called. After this time has elapsed, we
bail out without having acquired a lock. Default: 60 seconds.
If set to 0, the lock acquisition effectively becomes non-blocking.

I<timeout_stale> indicates the number of seconds since the creation of
an existing lock file, after which this alien lock file is to be considered stale.
A stale lock will be removed and replaced with our own lock (watch out!).
Default: 5 minutes. Set this to 0 to disable the feature.

I<unique_token> is an optional parameter that will uniquely identify
the lock. If you want to attempt locking the same file from
the same process in different locations, they must set
a unique token (host name, process id and thread id are used additionally).
Set this to C<1> to have a random token auto-generated.

=cut

SCOPE: {
  my @chars = ('a'..'z', 'A'..'Z', 0..9);
  sub new {
    my $class = shift;
    my %args = @_;
    croak("Need 'file' argument!")
      if not defined $args{file};

    my $uniquetoken = delete $args{unique_token};
    if (defined $uniquetoken) {
      if ($uniquetoken eq '1') {
        $args{token} = join '', map $chars[rand @chars], (1..20);
      }
      else {
        $args{token} = $uniquetoken;
      }
    }

    my $self = bless {
      poll_interval   => 1., # seconds
      timeout_acquire => 60., # seconds
      timeout_stale   => 5*60., # seconds
      token           => '',
      %args,
      hostname => Sys::Hostname::hostname(),
    } => $class;
    if (DEBUG) {
      warn "New lock for file '$self->{file}' (not acquired yet).\n"
          ."Time out for acquisition: $self->{timeout_acquire}\n"
          ."Time out for stale locks: $self->{timeout_stale}\n"
          ."Poll interval           : $self->{poll_interval}\n";
    }
    return $self;
  }
} # end SCOPE

=head2 lock

Attempts to acquire a lock on the file.
Returns 1 on success, 0 on failure (time out).

=cut

sub lock {
  my $self = shift;
  warn "Getting lock on ".$self->{file}."\n" if DEBUG;

  return 1 if $self->got_lock;
  warn "It is not locked already... ".$self->{file}."\n" if DEBUG;

  my $before_time = Time::HiRes::time();
  warn "Before time is $before_time\n" if DEBUG;
  while (1) {
    if ($self->_write_lock_file()) {
      return 1;
    } else {
      # check whether lock is stale
      if ($self->_is_stale_lock) {
        unlink $self->_lock_file;
        unlink $self->_unique_lock_file;
      } else {
        # hmm. lock valid, wait a bit or bail out
        my $now = Time::HiRes::time();
        warn "Time now is $now\n" if DEBUG;
        if ($now-$before_time > $self->{timeout_acquire}) {
          $self->_unlink_lock_file;
          return 0;
        }

        Time::HiRes::sleep($self->{poll_interval}) if $self->{poll_interval};
      }
    }
  } # end while(1)
}

=head2 unlock

Releases the lock, deletes the lock file.
This is automatically called on destruction of the
lock object!

=cut

sub unlock {
  my $self = shift;
  $self->_unlink_lock_file;
}

=head2 got_lock

Checks whether we have the lock on the file. Prefer calling got_lock() instead
of its older form, locked().

I<Note:> This is a fairly expensive operation requiring a C<stat> call.

=cut

sub got_lock {
  my $self = shift;
  # Check whether somebody else timed out the lock
  my $nlinks = ( stat($self->_unique_lock_file) )[STAT_NLINKS];
  if ( (defined $nlinks) and ($nlinks == 2) ) {
    warn "got_lock: LOCKED with ".$self->_unique_lock_file."\n" if DEBUG;
    return 1;
  } else {
    warn "got_lock: NOT LOCKED with ".$self->_unique_lock_file."\n" if DEBUG;
    return 0;
  }
}
*locked = \&got_lock;

=head2 is_locked

Checks file is currently locked by someone.

=cut

sub is_locked {
  # Simply check for presence of lock_file
  return (-f shift->_lock_file) ? 1 : 0;
}


=head2 wait

Wait until the file becomes free of any lock. This uses the I<poll_interval>
constructor passed to new().

=cut

sub wait {
  my $self = shift;
  while ( $self->is_locked ) {
    Time::HiRes::sleep($self->{poll_interval}) if $self->{poll_interval};
  }
  return 1;
}

sub DESTROY {
  my $self = shift;
  $self->unlock;
}

sub _unlink_lock_file {
  my $self = shift;
  if ($self->got_lock) {
    warn "_unlink_lock_file: locked, removing main lock file\n" if DEBUG;
    unlink($self->_lock_file);
  }
  warn "_unlink_lock_file: removing unique lock file\n" if DEBUG;
  unlink($self->_unique_lock_file);
}

sub _write_lock_file {
  my $self = shift;
  my $unique_lock_file = $self->_unique_lock_file;
  unlink($unique_lock_file) if -e $unique_lock_file;

  # Create process-specific lock file
  open my $fh, '>', $unique_lock_file
    or die "Could not open unique lock file for writing: $!";
  print $fh Time::HiRes::time(), "\012", $unique_lock_file, "\012";
  close $fh;

  # Attempt locking via linking
  my $linked = link($unique_lock_file, $self->_lock_file);
  if ( (not $linked) && ($! =~ m/not permitted/i) ) {
    die "Error: The filesystem that holds file ".$self->{file}." does not ".
      "support link().\n";
  }

  return $self->got_lock
}

sub _unique_lock_file {
  my $self = shift;
  return $self->{unique_lock_file} if defined $self->{unique_lock_file};
  my $thread_id = exists $INC{'threads.pm'} ? threads->tid : '';
  my $unique_lock_file = join( '.',
    $self->_lock_file, $self->{hostname}, $$, $thread_id, $self->{token});
  $self->{unique_lock_file} = $unique_lock_file;
  return $self->{unique_lock_file};
}

sub _lock_file {
  my $self = shift;
  return $self->{lock_file} if defined $self->{lock_file};
  my ($volume, $path, $lock_file) = File::Spec->splitpath( $self->{file} );
  $lock_file .= '.lock';
  $lock_file = File::Spec->catpath($volume, $path, $lock_file);
  $self->{lock_file} = $lock_file;
  return $lock_file;
}

sub _is_stale_lock {
  my $self = shift;
  return 0 if not $self->{timeout_stale};

  open my $fh, '<', $self->_lock_file # race?
    or return 1; # FIXME warning?

  local $/ = "\012";
  my @lines = <$fh>;
  if (Time::HiRes::time()-$lines[0] > $self->{timeout_stale}) {
    return 1;
  }
  return 0;
}

1;

__END__

=head1 CAVEATS

=head2 Lack of link() support

Some filesystems such as FAT32 do not support linking files. If the file you
want to lock is on such a filesystem, you will receive an error message.

Note: FAT32 is mostly relegated to USB sticks nowadays. No sane server will use
NFS-mounted FAT32 filesystems.

=head2 Testing

Basic unit tests are in place for this module. However, it is not extensively
tested (Patches welcome!). While the module is used on production systems here,
do your own testing since it may contain hidden race conditions.

Born out of frustration with existing locking modules.

=head1 SEE ALSO

L<File::NFSLock>, but that doesn't work for multiple machines (just for a single
machine and multiple processes).

L<Time::HiRes> is used to implement fractional-second C<sleep()> and C<time()>
calls.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
