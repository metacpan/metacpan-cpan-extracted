package IPC::Lock::Memcached;

use strict;
use warnings;

use base qw(IPC::Lock);

sub memcached {
  my $self = shift;
  $self->{memcached} ||= do {
    unless($self->{memcached_servers}) {
      die "need \$self->{memcached_servers}, check perldoc for usage";
    }
    require Cache::Memcached;
    Cache::Memcached->new({
      servers => $self->{memcached_servers},
    });
  };
}

sub atomic {
  my $self = shift;
  my $key = shift;
  my $ttl = shift;

  return $self->memcached->add($key, $self->atomic_value, $ttl);
}

sub unatomic {
  my $self = shift;
  my $key = shift || $self->{key};
  return $self->memcached->delete($key);
}

1;

__END__

=head1 NAME

IPC::Lock::Memcached - memcached based locking

=head1 SYNOPSIS

  IPC::Lock::Memcached extends IPC::Lock, and uses add and delete
  for its atomic and unatomic methods.

  use IPC::Lock::Memcached;
  {
      my $lock = IPC::Lock::Memcached->new({
        memcached_servers => ["localhost:11211"],
      });
      ### following memcached tradition, spaces are not allowed in the key name
      ### and the user is expected to check such things themselves
      if($lock->lock("magic_key")) {

        ###
        ### do your thing
        ###    
        
        $lock->unlock;
      }
  }

  When $lock leaves scope, $lock->unlock gets called.  When called via
  destroy, unlock will destroy the last $key that was locked.  To avoid
  relying on this magic, call $lock->unlock explicitly.

=head1 A LITTLE WARNING

  If you are running your Memcached servers right on the edge of memory capacity,
  IPC::Lock::Memcached might not be for you.  Also, if you lose a memcached server,
  you will lose your ability to lock.  Probably your $lock->lock method will never
  return true.  Along similar lines, make sure you write your code tests to make
  sure you actually got the lock.  Like

  if($lock->lock("coolkey")) {
  }

=head1 BENCHMARKS

  Using a dual 1 ghz box

  Local test without an extant memcached object

  timethese(-5, {
    lock => sub {
      my $lock = IPC::Lock::Memcached->new({
        memcached_servers => ["localhost:11211"],
      });

      if($lock->lock("coolkey")) {
        $lock->unlock;
      }
    }
  });

  Benchmark: running lock for at least 5 CPU seconds...
    lock:  6 wallclock secs ( 4.59 usr +  0.53 sys =  5.12 CPU) @ 2302.54/s (n=11789)

  Local test with an extant memcached object

  my $lock = IPC::Lock::Memcached->new({
    memcached_servers => ["localhost:11211"],
  });

  timethese(-5, {
    lock => sub {

      if($lock->lock("coolkey")) {
        $lock->unlock;
      }
    }
  });

  Benchmark: running lock for at least 5 CPU seconds...
    lock:  7 wallclock secs ( 4.26 usr +  0.87 sys =  5.13 CPU) @ 3844.44/s (n=19722)

  Pretty dang fast.  In other memcached benchmarks, for me, 
  remote calls have actually been faster than local.


=head1 THANKS

Thanks to Brad Fitzpatrick for Cache::Memcached.  It just works.
Thanks to Perrin Harkins for a little review and encouraging me to add a warning.

=head1 AUTHOR

Earl Cahill, <cpan@spack.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Earl Cahill

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
