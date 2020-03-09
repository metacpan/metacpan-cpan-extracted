use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Doodle::Library

=cut

=abstract

Doodle Type Library

=cut

=synopsis

  use Doodle::Library;

=cut

=description

Doodle::Library is the L<Doodle> type library derived from
L<Data::Object::Types> which is a L<Type::Library>.

=cut

=libraries

Data::Object::Types

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

ok 1 and done_testing;
