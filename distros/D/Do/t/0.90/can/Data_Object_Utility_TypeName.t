use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

TypeName

=usage

  # given ...

  Data::Object::Utility::TypeName(...);

=description

The C<TypeName> function returns a data type description for the type of data
provided, represented as a string in capital letters.

=signature

TypeName(Any $arg1) : Str

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "TypeName";

use Scalar::Util 'refaddr';

my $array = Data::Object::Utility::TypeName [1 .. 5];
is $array, 'ARRAY';

my $code = Data::Object::Utility::TypeName sub {1};
is $code, 'CODE';

my $float = Data::Object::Utility::TypeName 3.98765;
is $float, 'FLOAT';

my $power = Data::Object::Utility::TypeName '1.3e8';
is $power, 'FLOAT';

my $hash = Data::Object::Utility::TypeName { 1 .. 4 };
is $hash, 'HASH';

my $integer = Data::Object::Utility::TypeName 99;
is $integer, 'NUMBER';

my $pos_number = Data::Object::Utility::TypeName '+12345';
is $pos_number, 'NUMBER';

my $neg_number = Data::Object::Utility::TypeName '-12345';
is $neg_number, 'NUMBER';

my $regexp = Data::Object::Utility::TypeName qr/\w+/;
is $regexp, 'REGEXP';

my $string = Data::Object::Utility::TypeName 'Hello World';
is $string, 'STRING';

my $undef = Data::Object::Utility::TypeName undef;
is $undef, 'UNDEF';

ok 1 and done_testing;
