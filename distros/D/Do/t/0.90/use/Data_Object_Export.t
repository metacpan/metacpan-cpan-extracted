use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Export

=abstract

Data-Object Keyword Functions

=synopsis

  use Data::Object::Export;

  my $num = cast 123; # Data::Object::Number
  my $str = cast 123, 'string'; # Data::Object::String

=inherits

Exporter

=description

This package is an exporter that provides a few simple keyword functions to
every calling package.

+=head1 EXPORTS

This package can export the following functions.

+=head2 all

  use Data::Object::Export ':all';

The all export tag will export the exportable functions, i.e. C<cast>,
C<const>, C<do>, C<is_false>, C<is_true>, C<false>, C<true>, and C<raise>.

=cut

use_ok 'Data::Object::Export';

can_ok 'Data::Object::Export', 'cast';
can_ok 'Data::Object::Export', 'const';
can_ok 'Data::Object::Export', 'do';
can_ok 'Data::Object::Export', 'dump';
can_ok 'Data::Object::Export', 'false';
can_ok 'Data::Object::Export', 'is_false';
can_ok 'Data::Object::Export', 'is_true';
can_ok 'Data::Object::Export', 'load';
can_ok 'Data::Object::Export', 'raise';
can_ok 'Data::Object::Export', 'true';

ok 1 and done_testing;
