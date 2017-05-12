use strict;
use warnings;
package InstanceX;

use Scalar::Util qw(blessed);

our $VERSION = '1.000';

my %STATIC = (
  new => sub {
    my ($class, $arg) = @_;
    bless $arg => $class;
  }
);

my %UNIVERSAL = (
  class => sub { $_[0]->{__class__} }, # shout out to my homies in python
  isa   => sub { return $_[0]->class->derives_from($_[1]); },
);

sub invoke_method {
  my ($invocant, $method_name, $args) = @_;

  my $code;

  unless (ref $invocant) {
    $code = $STATIC{$method_name};
    die "no metaclass method $method_name on $invocant" unless $code;

    return $code->($invocant, @$args);
  }

  my $class = $invocant->{__class__};
  my $curr  = $class;

  while ($curr) {
    my $methods = $curr->instance_methods;

    $code = $methods->{$method_name}, last
      if exists $methods->{$method_name};
    $curr = $curr->base;
  }

  unless ($code ||= $UNIVERSAL{$method_name}) {
    my $msg = sprintf "no instance method %s on %s(%s)",
      $method_name, ref($invocant), $class->name;
    die $msg;
  }

  $code->($invocant, @$args);
};

use MRO::Magic
  metamethod => \'invoke_method',
  passthru   => [ qw(VERSION DESTROY AUTOLOAD import unimport) ];

{ package Instance; use mro 'InstanceX'; }

1;
