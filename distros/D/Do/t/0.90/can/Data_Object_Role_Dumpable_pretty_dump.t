use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

pretty_dump

=usage

  my $pretty_dump = $self->pretty_dump();

=description

The pretty_dump method returns a string representation of the underlying data
that is human-readable and useful for debugging.

=signature

  pretty_dump() : Str

=type

method

=cut

# TESTING

use_ok 'Data::Object::Role::Dumpable';

use_ok 'Data::Object::Array';
use_ok 'Data::Object::Code';
use_ok 'Data::Object::Float';
use_ok 'Data::Object::Hash';
use_ok 'Data::Object::Number';
use_ok 'Data::Object::Scalar';
use_ok 'Data::Object::String';
use_ok 'Data::Object::Undef';

my $data = 'Data::Object::Role::Dumpable';

can_ok $data, 'pretty_dump';

my $array = Data::Object::Array->new([1, 2, 3, 4, 5]);
is $array->pretty_dump, q{[
  1,
  2,
  3,
  4,
  5
]};

my $code = Data::Object::Code->new(sub {1});
my $dump = $code->pretty_dump;
like $dump, qr/sub.*\n\s+package.*Data::Object.*;\n.*goto \$data/s;

my $float = Data::Object::Float->new(3.99);
is $float->pretty_dump, "3.99";

my $hash = Data::Object::Hash->new({1, 2, 3, 4});
is $hash->pretty_dump, q{{
  1 => 2,
  3 => 4
}};

my $number = Data::Object::Number->new(12345);
is $number->pretty_dump, "12345";

my $arrayref = [1, 2, 3];
my $scalar   = Data::Object::Scalar->new($arrayref);
is $scalar->pretty_dump, q([
  1,
  2,
  3
]);

my $string = Data::Object::String->new('abcdefghi');
is $string->pretty_dump, "abcdefghi";

my $undef = Data::Object::Undef->new(undef);
is $undef->pretty_dump, "undef";

ok 1 and done_testing;
