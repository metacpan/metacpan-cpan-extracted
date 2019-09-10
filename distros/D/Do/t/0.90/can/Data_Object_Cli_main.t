use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

main

=usage

  # $args{args} = $self->args; # represents @ARGV
  # $args{data} = $self->data; # represents __DATA__
  # $args{opts} = $self->opts; # represents Getopt::Long
  # $args{vars} = $self->vars; # represents %ENV

  $self->main(%args)

=description

The main method is the "main method" and entrypoint into the program. It's
called automatically by the C<run> method if your package is configured as
recommended. This method accepts arguments as key/value pairs, and if called by
C<run> will receive the C<args>, C<data>, C<opts>, and C<vars> objects.

=signature

main(Any %args) : Any

=type

method

=cut

# TESTING

use Data::Object::Cli;

can_ok "Data::Object::Cli", "main";

{
  package Command;

  use Moo;

  extends 'Data::Object::Cli';

  sub spec {
    []
  }

  sub sign {
    {}
  }

  1;
}

my $command = Command->new;

ok $command->main;

ok 1 and done_testing;
