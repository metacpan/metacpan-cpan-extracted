use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

choose

=usage

  choose('class');

=description

The choose function returns the configuration (plans) based on the argument passed.

=signature

choose(Str $arg1) : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'choose';

is_deeply Data::Object::Config::choose(), ['config_core', 1];
is_deeply Data::Object::Config::choose('Core'), ['config_core', 1];
is_deeply Data::Object::Config::choose('core'), ['config_core', 1];
is_deeply Data::Object::Config::choose(':Core'), ['config_core', 1];
is_deeply Data::Object::Config::choose(':core'), ['config_core', 1];
is_deeply Data::Object::Config::choose(':Class'), ['config_class', 1];
is_deeply Data::Object::Config::choose(':Cli'), ['config_cli', 1];
is_deeply Data::Object::Config::choose(':Role'), ['config_role', 1];
is_deeply Data::Object::Config::choose(':Rule'), ['config_rule', 1];
is_deeply Data::Object::Config::choose(':class'), ['config_class', 1];
is_deeply Data::Object::Config::choose(':cli'), ['config_cli', 1];
is_deeply Data::Object::Config::choose(':role'), ['config_role', 1];
is_deeply Data::Object::Config::choose(':rule'), ['config_rule', 1];

is_deeply Data::Object::Config::choose('Class'), ['config_class', 1];
is_deeply Data::Object::Config::choose('Cli'), ['config_cli', 1];
is_deeply Data::Object::Config::choose('Role'), ['config_role', 1];
is_deeply Data::Object::Config::choose('Rule'), ['config_rule', 1];
is_deeply Data::Object::Config::choose('class'), ['config_class', 1];
is_deeply Data::Object::Config::choose('cli'), ['config_cli', 1];
is_deeply Data::Object::Config::choose('role'), ['config_role', 1];
is_deeply Data::Object::Config::choose('rule'), ['config_rule', 1];

is_deeply Data::Object::Config::choose(':pl'), ['config_cli', 1];
is_deeply Data::Object::Config::choose(':pm'), ['config_class', 1];
is_deeply Data::Object::Config::choose('PL'), ['config_cli', 1];
is_deeply Data::Object::Config::choose('PM'), ['config_class', 1];
is_deeply Data::Object::Config::choose('pl'), ['config_cli', 1];
is_deeply Data::Object::Config::choose('pm'), ['config_class', 1];

ok 1 and done_testing;
