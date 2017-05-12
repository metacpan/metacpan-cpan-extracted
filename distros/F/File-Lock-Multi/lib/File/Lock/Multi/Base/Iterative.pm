#!perl

package File::Lock::Multi::Base::Iterative;

use strict;
use warnings (FATAL => 'all');

use File::Lock::Multi::Base;
use base q(File::Lock::Multi::Base);
use Time::HiRes qw(sleep);

__PACKAGE__->mk_accessors(qw(iteration_delay));

return 1;

sub _lock {
  my $self = shift;
  return $self->_iterate(sub {
    my($me, $now) = @_;
    return $me->lock_non_block_for($now);
  });
}

sub lockers {
  my $self = shift;
  my @lockers = ();
  $self->_iterate(sub {
    my($me, $now) = @_;
    push(@lockers, $now) if($me->lock_held_for($now));
    return;
  });
  return @lockers;
}

sub lock_held_for {
  my $self = shift;
  return !$self->obtain_lock_for(@_);
}

sub _iterate {
  my($self, $code) = @_;
  my $max = $self->max;
  my $now = 1;
  my $delay = $self->iteration_delay;
  my $rv;

  while($now <= $max) {
    if(my $rv = $code->($self, $now)) {
      return $rv;
    }
    $now++;
    sleep($delay) if $delay && $now <= $max;
  }
  return;
}


