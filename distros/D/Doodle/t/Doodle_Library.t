use 5.014;

use Do;
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
L<Data::Object::Library> which is a L<Type::Library>.

=cut

=libraries

Data::Object::Library

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

ok 1 and done_testing;
