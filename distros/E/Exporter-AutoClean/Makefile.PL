use inc::Module::Install;
name 'Exporter-AutoClean';
all_from 'lib/Exporter/AutoClean.pm';

requires 'B::Hooks::EndOfScope';

test_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
