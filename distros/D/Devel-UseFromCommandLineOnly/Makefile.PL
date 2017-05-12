use inc::Module::Install;

# Define metadata
name           'Devel-UseFromCommandLineOnly';
all_from       'lib/Devel/UseFromCommandLineOnly.pm';

test_requires  'Test::More'  => '0';

license 'perl';

auto_set_repository;

WriteAll;
