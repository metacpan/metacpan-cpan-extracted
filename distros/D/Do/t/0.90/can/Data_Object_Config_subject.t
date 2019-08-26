use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

subject

=usage

  subject('Role', 'Role');

=description

The subject function returns truthy if both arguments match alphanumerically
(not case-sensitive).

=signature

subject(Str $arg1, Str $arg2) : Int

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'subject';

is_deeply Data::Object::Config::subject(1, 1), 1;
is_deeply Data::Object::Config::subject('A', 'a'), 1;
is_deeply Data::Object::Config::subject('-a', 'A'), 1;
is_deeply Data::Object::Config::subject('b', 'B'), 1;
is_deeply Data::Object::Config::subject('-B', 'b'), 1;
is_deeply Data::Object::Config::subject('c', 'a'), 0;
is_deeply Data::Object::Config::subject('C', 'A'), 0;
is_deeply Data::Object::Config::subject('-c', 'a'), 0;

ok 1 and done_testing;
