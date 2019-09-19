use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Deduce

=usage

  # given ...

  Data::Object::Utility::Deduce(...);

=description

The C<Deduce> function returns a data type object instance based upon the
deduced type of data provided.

=signature

Deduce(Any $arg1) : Any

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "Deduce";

my $array = Data::Object::Utility::Deduce [1 .. 5];
isa_ok $array, 'Data::Object::Array';

my $code = Data::Object::Utility::Deduce sub {1};
isa_ok $code, 'Data::Object::Code';

my $float = Data::Object::Utility::Deduce 3.98765;
isa_ok $float, 'Data::Object::Float';

my $power = Data::Object::Utility::Deduce '1.3e8';
isa_ok $power, 'Data::Object::Float';

my $hash = Data::Object::Utility::Deduce { 1 .. 4 };
isa_ok $hash, 'Data::Object::Hash';

my $integer = Data::Object::Utility::Deduce 99;
isa_ok $integer, 'Data::Object::Number';

my $number = Data::Object::Utility::Deduce '+12345';
isa_ok $number, 'Data::Object::Number';

my $regexp = Data::Object::Utility::Deduce qr/\w+/;
isa_ok $regexp, 'Data::Object::Regexp';

my $string = Data::Object::Utility::Deduce 'Hello World';
isa_ok $string, 'Data::Object::String';

my $undef = Data::Object::Utility::Deduce undef;
isa_ok $undef, 'Data::Object::Undef';

ok 1 and done_testing;
