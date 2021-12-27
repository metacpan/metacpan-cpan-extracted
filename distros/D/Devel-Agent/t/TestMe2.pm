package 
  TestMe2;

use Modern::Perl;
use Moo;
use Data::Dumper;
our $AUTOLOAD;
extends 'TestMe';


sub test_a {
  my ($self)=@_;
  $self->SUPER::test_a(456);
}

sub can {
  my ($self,$method)=@_;

  my $cb=$self->SUPER::can($method);
  return $cb if $cb;

  return sub {
    $AUTOLOAD=$method;
    my $self=shift;
    $self->AUTOLOAD(@_);
  };
}

sub AUTOLOAD {
  my $self=shift;
  return [@_];
}

sub DEMOLISH {
  my ($self)=@_;
}

1;
