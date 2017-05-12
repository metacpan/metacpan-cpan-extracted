use inc::Module::Install;
all_from 'lib/Email/Address/JP/Mobile.pm';

requires 'Email::Address::Loose';
requires 'Encode';
requires 'Encode::JP::Mobile' => 0.27; # mime encodings

test_requires 'Email::Address';
test_requires 'Test::More' => 0.96; # subtest / done_testing
include 'Test::Builder'; # for Test::Builder 2.x tester
auto_include_deps;

tests_recursive;

readme_from 'lib/Email/Address/JP/Mobile.pm';

repository 'http://github.com/tomi-ru/Email-Address-JP-Mobile';
bugtracker 'http://github.com/tomi-ru/Email-Address-JP-Mobile/issues';

WriteAll;
