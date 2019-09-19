use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Name

=abstract

Data-Object Name Class

=synopsis

  use Data::Object::Name;

  my $name;

  $name = Data::Object::Name->new('Foo/Bar');
  $name = Data::Object::Name->new('Foo::Bar');
  $name = Data::Object::Name->new('Foo__Bar');
  $name = Data::Object::Name->new('foo__bar');

  my $file = $name->file; # foo__bar
  my $package = $name->package; # Foo::Bar
  my $path = $name->path; # Foo/Bar
  my $label = $name->label; # Foo__Bar

=description

This package provides methods for converting name strings, e.g. package names,
file names, path names, and label names, to and from each other.

=cut

use_ok "Data::Object::Name";

ok 1 and done_testing;
