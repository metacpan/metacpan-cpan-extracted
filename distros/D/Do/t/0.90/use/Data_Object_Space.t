use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Space

=abstract

Data-Object Space Class

=synopsis

  use Data::Object::Space;

  my $space = Data::Object::Space->new('data/object');

  "$space"
  # Data::Object

  $space->name;
  # Data::Object

  $space->path;
  # Data/Object

  $space->file;
  # Data/Object.pm

  $space->children;
  # ['Data/Object/Array.pm', ...]

  $space->siblings;
  # ['Data/Dumper.pm', ...]

  $space->load;
  # Data::Object

=libraries

Data::Object::Library

=description

This package provides methods for parsing and manipulating package namespaces.

=cut

use_ok "Data::Object::Space";

ok 1 and done_testing;
