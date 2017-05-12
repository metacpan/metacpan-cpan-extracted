use inc::Module::Install;

all_from('lib/Exception/Simple.pm');

requires 'overload';
test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'parent';

perl_version '5.008';

resources(
    'bugtracker'  => 'https://github.com/markwellis/exception-simple/issues',
    'repository'  => 'https://github.com/markwellis/exception-simple.git',
);

auto_install;
WriteAll;
