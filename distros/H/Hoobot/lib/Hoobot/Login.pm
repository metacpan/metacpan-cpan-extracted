# SOAP::Lite style Hoobot::Login

package Hoobot::Login;

use strict;
use warnings;
use Hoobot::Page;

our @ISA = qw/Hoobot::Page/;

sub username {
  my $self = shift;
  $self = $self->new unless ref $self;
  return $self->{username} unless @_;

  $self->{username} = shift;

  return $self;
}

sub password {
  my $self = shift;
  $self = $self->new unless ref $self;
  return $self->{password} unless @_;

  $self->{password} = shift;

  return $self;
}

sub prepare_update {
  my $self = shift;
  $self = $self->new unless ref $self;

  # site doesn't matter, skin doesn't matter
  $self
    -> page('RegProcess')
    -> method('POST')
    -> clear_params
    -> param(bbctest => 1)
    -> param(cmd => 'fasttrack')
    -> param(loginname => $self->username)
    -> param(password => $self->password)
    -> param(remember => 1)
    -> param(submit => 'Login');

  return $self->SUPER::prepare_update;
}


1;
