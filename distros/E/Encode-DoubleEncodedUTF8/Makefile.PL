use inc::Module::Install;
name 'Encode-DoubleEncodedUTF8';
all_from 'lib/Encode/DoubleEncodedUTF8.pm';
readme_from 'lib/Encode/DoubleEncodedUTF8.pm';

requires 'Encode', 0.12;

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
