use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Detract

=usage

  # given ...

  Data::Object::Utility::Detract(...);

=description

The C<Detract> function returns a value of native type, based upon the
underlying reference of the data type object provided.

=signature

Detract(Any $arg1) : Any

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "Detract";

use Scalar::Util 'refaddr';

my $array = Data::Object::Utility::Deduce [1 .. 5];
isa_ok $array, 'Data::Object::Array';
is_deeply Data::Object::Utility::Detract($array), [1 .. 5];

my $code = Data::Object::Utility::Deduce sub {1};
isa_ok $code, 'Data::Object::Code';
is Data::Object::Utility::Detract($code)->(), 1;

my $float = Data::Object::Utility::Deduce 3.98765;
isa_ok $float, 'Data::Object::Float';
is Data::Object::Utility::Detract($float), 3.98765;

my $power = Data::Object::Utility::Deduce '1.3e8';
isa_ok $power, 'Data::Object::Float';
is Data::Object::Utility::Detract($power), '1.3e8';

my $hash = Data::Object::Utility::Deduce { 1 .. 4 };
isa_ok $hash, 'Data::Object::Hash';
is_deeply Data::Object::Utility::Detract($hash), {1 .. 4};

my $integer = Data::Object::Utility::Deduce 99;
isa_ok $integer, 'Data::Object::Number';
is Data::Object::Utility::Detract($integer), 99;

my $number = Data::Object::Utility::Deduce '+12345';
isa_ok $number, 'Data::Object::Number';
is Data::Object::Utility::Detract($number), 12345;

my $regexp = Data::Object::Utility::Deduce qr/\w+/;
isa_ok $regexp, 'Data::Object::Regexp';
is Data::Object::Utility::Detract($regexp), qr/\w+/;

my $string = Data::Object::Utility::Deduce 'Hello World';
isa_ok $string, 'Data::Object::String';
is Data::Object::Utility::Detract($string), 'Hello World';

my $undef = Data::Object::Utility::Deduce undef;
isa_ok $undef, 'Data::Object::Undef';
is Data::Object::Utility::Detract($undef), undef;

ok 1 and done_testing;
