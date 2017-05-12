use inc::Module::Install;
name 'Encode-First';
all_from 'lib/Encode/First.pm';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
