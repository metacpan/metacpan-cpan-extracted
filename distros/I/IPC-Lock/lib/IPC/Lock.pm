package IPC::Lock;

use strict;
use warnings;

use Time::HiRes qw(gettimeofday);

our $VERSION    = '0.20';
our @CATCH_SIGS = qw(TERM INT);

### from File::NFSLock
my $graceful_sig = sub {
    print STDERR "Received SIG$_[0]\n" if @_;
  # Perl's exit should safely DESTROY any objects
  # still "alive" before calling the real _exit().
    exit;
};

sub new {
    my $type  = shift;
    my @PASSED_ARGS = (ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
    my @DEFAULT_ARGS = (
        locked    => {},
        ttl       => 60,
        patience  => 2,
        increment => '0.05',
    );

    my %ARGS = (@DEFAULT_ARGS, @PASSED_ARGS);
    unless($ARGS{hostname}) {
        require Sys::Hostname;
        $ARGS{hostname} = &Sys::Hostname::hostname();
    }

    foreach my $signal (@CATCH_SIGS) {
        if (!$SIG{$signal} || $SIG{$signal} eq "DEFAULT") {
            $SIG{$signal} = $graceful_sig;
        }
    }
    return bless \%ARGS, $type;
}

sub lock {
    my $self = shift;
    my $key = shift || die "need a key";
    $self->{key} = $key;

    my $ttl = shift;
    $ttl = $self->{ttl} unless( (defined $ttl) && length $ttl);

    my $patience = $self->{patience};
    my $increment = $self->{increment};

    my $start = gettimeofday;

    my $got_lock = 0;

    while(1) {
        if($self->atomic($key, $ttl)) {
            $self->{locked}{$key} = 1;
            $got_lock = 1;
            last;
        }
        last if(gettimeofday - $start > $patience);
        select(undef, undef, undef, $increment);
    }

    return $got_lock;
}

sub unlock {
    my $self = shift;
    my $key = shift || $self->{key} || die "need a key";
    my $unlock = $self->unatomic($key);
    if($unlock) {
        delete $self->{locked}{$key};
    }
    return $unlock;
}

sub DESTROY {
    my $self = shift;

    if($self->{locked} && $self->{key} && $self->{locked}{$self->{key}}) {
        $self->unlock($self->{key});
    }
}

sub atomic_value {
    my $self = shift;
    return "$self->{hostname}:$$:" . scalar gettimeofday;
}

sub atomic {
    die "please write your own atomic method";
}

sub unatomic {
    die "please write your own unatomic method";
}

1;

__END__

=head1 NAME

IPC::Lock - simple and safe local/network locking

=head1 SYNOPSIS

  IPC::Lock is a base module and depends on other objects to implement it.

  Current modules include IPC::Lock::Memcached.  
  
  Please refer to a child module for their respective usage.

  Generally, you instantiate a $lock object via new.  The new will contain
  connection parameters.
  
  Then call

  $lock->lock($key)

  where $key is a unique identifier.  The default value set for the lock comes
  from $self->atomic_value, which by default is

  return "$self->{hostname}:$$:" . scalar gettimeofday;
  
  The value can potentially be used for debugging.
  
  When $lock leaves scope,

  $lock->unlock

  gets called.  When called via destroy, unlock will destroy the last 
  $key that was locked.  To avoid relying on this magic, call 
  $lock->unlock explicitly.

=head1 PARAMETERS

  The following parameters can be set in the instantiation:

  ttl       - number of seconds the lock should last, default is 60
  patience  - number of seconds to wait for a lock, default is 2
  increment - number of seconds to wait between atomic attempts, default is 0.05

  So, to instantiate with a ttl of a day, patience of a minute and increment of a second

  my $lock = IPC::Lock::Child->new({
      ttl       => 86400,
      patience  => 60,
      increment => 1,
  });

=head1 DESCRIPTION

  Simple way to lock across multiple boxes.  Child modules need to implement two methods

  atomic - a way to lock atomically
  unatomic - a way to undo your atomic function

=head1 THANKS

Thanks to Perrin Harkins for suggesting the IPC::Lock namespace.
Thanks to File::NFSLock for graceful_sig.

=head1 AUTHOR

Earl Cahill, <cpan@spack.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Earl Cahill

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
