use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Cli

=abstract

Data-Object CLI Base Class

=synopsis

  package Command;

  use Data::Object 'Class';

  extends 'Data::Object::Cli';

  method main() {
    say $self->help->list;
  }

  run Command;

  __DATA__

  =pod help

  Do something!

  =pod sign

  {command}

  =pod spec

  action=s, verbose|v

  =cut

=library

Data::Object::Library

=attributes

args(ArgsObject, opt, ro)
data(DataObject, opt, ro)
opts(OptsObject, opt, ro)
vars(VarsObject, opt, ro)

=description

This package provides an abstract base class for defining command-line
interface classes, which can be run as scripts or passed as objects in a more
complex system.

=cut

use_ok "Data::Object::Cli";

ok 1 and done_testing;
