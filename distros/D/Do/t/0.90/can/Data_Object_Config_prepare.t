use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

prepare

=usage

  prepare($package, $type);

=description

The prepare function returns configuration plans based on the arguments passed.

=signature

prepare(Str $arg1, Str $arg2) : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'prepare';

my $plans;

$plans = Data::Object::Config::prepare('main');

is_deeply $plans->[0], ['use', 'strict'];
is_deeply $plans->[1], ['use', 'warnings'];
is_deeply $plans->[2], ['use', 'feature', ':5.14'];
is_deeply $plans->[3], ['use', 'Data::Object::Library'];
is_deeply $plans->[4], ['use', 'Data::Object::Signatures'];
is_deeply $plans->[5], ['use', 'Data::Object::Autobox'];
is_deeply $plans->[6], ['use', 'Data::Object::Export'];

$plans = Data::Object::Config::prepare('main', 'core'); # doesn't fail?

is_deeply $plans->[0], ['use', 'strict'];
is_deeply $plans->[1], ['use', 'warnings'];
is_deeply $plans->[2], ['use', 'feature', ':5.14'];
is_deeply $plans->[3], ['use', 'Data::Object::Library'];
is_deeply $plans->[4], ['use', 'Data::Object::Signatures'];
is_deeply $plans->[5], ['use', 'Data::Object::Autobox'];
is_deeply $plans->[6], ['use', 'Data::Object::Export'];

$plans = Data::Object::Config::prepare('main', 'class');

is_deeply $plans->[0], ['use', 'strict'];
is_deeply $plans->[1], ['use', 'warnings'];
is_deeply $plans->[2], ['use', 'feature', ':5.14'];
is_deeply $plans->[3], ['use', 'Data::Object::Library'];
is_deeply $plans->[4], ['use', 'Data::Object::Signatures'];
is_deeply $plans->[5], ['use', 'Data::Object::Autobox'];
is_deeply $plans->[6], ['use', 'Data::Object::Class'];
is_deeply $plans->[7], ['use', 'Data::Object::ClassHas'];
is_deeply $plans->[8], ['use', 'Data::Object::Export'];

$plans = Data::Object::Config::prepare('main', 'role');

is_deeply $plans->[0], ['use', 'strict'];
is_deeply $plans->[1], ['use', 'warnings'];
is_deeply $plans->[2], ['use', 'feature', ':5.14'];
is_deeply $plans->[3], ['use', 'Data::Object::Library'];
is_deeply $plans->[4], ['use', 'Data::Object::Signatures'];
is_deeply $plans->[5], ['use', 'Data::Object::Autobox'];
is_deeply $plans->[6], ['use', 'Data::Object::Role'];
is_deeply $plans->[7], ['use', 'Data::Object::RoleHas'];
is_deeply $plans->[8], ['use', 'Data::Object::Export'];

ok 1 and done_testing;
