use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Registry

=abstract

Data-Object Namespace Registry

=synopsis

  use Data::Object::Registry;

  my $registry = Data::Object::Registry->new;

=description

This package is a singleton that holds mappings for namespaces and type
libraries.

=cut

use_ok "Data::Object::Registry";

ok 1 and done_testing;
