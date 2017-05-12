use inc::Module::Install;
name 'Lingua-JA-Hepburn-Passport';
all_from 'lib/Lingua/JA/Hepburn/Passport.pm';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
