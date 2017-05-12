package File::Lock::Multi::Base;

use 5.006000;
use strict;
use warnings (FATAL => 'all');
use Class::Accessor;
use base q(Class::Accessor);
use Time::HiRes qw(sleep);
use Carp qw(croak);
use Params::Validate;
use Params::Classify qw(is_number);

__PACKAGE__->mk_accessors(qw(max name timeout polling_interval));

return 1;

# rename file -> name to make more sense with virtual resources
sub file { &name }

sub __Validators {
  my $class = shift;

  my $float_spec = { optional => 1, callbacks => { number => sub {
    is_number(shift)
  } }
  };;
  my $integer_spec = { optional => 1, regex => qr/^\d+$/ };

  return(
    name => 1,
    polling_interval => $float_spec,
    timeout => $float_spec,
    max => $integer_spec,
    @_
  );
}


sub new {
  my($class, %args_in) = @_;
  (my $subclass = __PACKAGE__) =~ s{::Base$}{};

  $args_in{name} = delete $args_in{file} if exists $args_in{file};
  # silliness to accomodate Params::Validate
  my @args_in = %args_in;

  croak "$class is a base class; please find a suitable subclass to use"
    if $class eq __PACKAGE__ || $class eq $subclass;

  my %validate_spec = $class->__Validators;
  my %args = validate(@args_in, \%validate_spec);

  $args{polling_interval} ||= 0.2;
  $args{timeout} = -1 unless defined $args{timeout};
  $args{max} ||= 1;

  return $class->SUPER::new(\%args);
}

sub lockable {
  my $self = shift;
  if($self->lock(0)) {
    return $self->release;
  } else {
    return;
  }
}

sub _lock_non_block {
  my $self = shift;

  croak("i already have a lock on ", $self->file) if $self->locked;

  if(my $id = $self->_lock) {
    if($self->lockers > $self->max) {
      $self->release;
      return;
    } else {
      return $id;
    }
  } else {
    return;
  }
}

sub lock {
  my $self = shift;

  my $timeout = scalar(@_) ? shift : $self->timeout;
  return $self->_lock_non_block unless $timeout;

  my $polling_interval = $self->polling_interval;

  if($timeout < 0) {
    while(1) {
      if(my $id = $self->_lock_non_block) {
        return $id;
      } else {
        sleep($polling_interval);
      }
    }
  } else {
    my $cycles = $timeout / $polling_interval;
    if($cycles < 1) {
      $cycles = 1;
      $polling_interval = $timeout;
    }

    while($cycles) {
      if(my $id = $self->_lock_non_block) {
        return $id;
      } else {
        sleep($polling_interval);
        $cycles --;
      }
    }
  }
}

sub release {
  my $self = shift;
  croak("i do not have a lock on ", $self->file) unless $self->locked;
  return $self->_release;
}

sub DESTROY {
  my $self = shift;
  $self->release if $self->locked;
}


