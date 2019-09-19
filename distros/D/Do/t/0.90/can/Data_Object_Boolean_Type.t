use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Type

=usage

  Data::Object::Boolean::Type($value); # "True" or "False"

=description

The Type function returns either "True" or "False" based on the truthiness or
falsiness of the argument provided.

=signature

Type() : Object

=type

function

=cut

# TESTING

use Data::Object::Boolean;

can_ok "Data::Object::Boolean", "Type";

my $type;

my $True = Data::Object::Boolean::True();
my $False = Data::Object::Boolean::False();

$type = Data::Object::Boolean::Type($True);
is $type, 'True';

$type = Data::Object::Boolean::Type(1);
is $type, 'True';

$type = Data::Object::Boolean::Type(\1);
is $type, 'True';

$type = Data::Object::Boolean::Type({});
is $type, 'True';

$type = Data::Object::Boolean::Type(bless {});
is $type, 'True';

$type = Data::Object::Boolean::Type($False);
is $type, 'False';

$type = Data::Object::Boolean::Type(0);
is $type, 'False';

$type = Data::Object::Boolean::Type('');
is $type, 'False';

$type = Data::Object::Boolean::Type(undef);
is $type, 'False';

$type = Data::Object::Boolean::Type(\0);
is $type, 'False';

ok 1 and done_testing;
