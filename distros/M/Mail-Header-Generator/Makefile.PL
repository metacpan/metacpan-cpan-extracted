use inc::Module::Install;

name     'Mail-Header-Generator';
all_from 'lib/Mail/Header/Generator.pm';
license  'gpl';

requires 'Time::Local';

test_requires 'Test::More';
test_requires 'Test::Class';

WriteAll;

