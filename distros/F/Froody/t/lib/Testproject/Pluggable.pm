package Testproject::Pluggable;

use strict;
use warnings;
use base 'Froody::Implementation';

sub implements { "Testproject::API" => "testproject.object.*" }

__PACKAGE__->register_plugin('Testproject::Plugin');

sub session_test {
   my ($self) = @_;
   return $self->session;
}

1;

