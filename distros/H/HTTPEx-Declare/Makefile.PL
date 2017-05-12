use inc::Module::Install;

{
    no warnings 'redefine';
    *recommends_hack = $Module::Install::VERSION > 0.70 ?
        sub { recommends(@_); $_[0] } :
        \&recommends;
}

name 'HTTPEx-Declare';
all_from 'lib/HTTPEx/Declare.pm';

requires 'HTTP::Engine' => '0.0.14';
requires 'Sub::Exporter';
requires 'Carp';

features(
    'Compat support' => [
        -default => 0,
        recommends_hack('HTTP::Engine::Compat'),
    ],
);

build_requires 'Test::More';

use_test_base;
auto_include;
WriteAll;
