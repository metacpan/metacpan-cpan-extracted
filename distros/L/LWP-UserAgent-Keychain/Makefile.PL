use inc::Module::Install;
name 'LWP-UserAgent-Keychain';
all_from 'lib/LWP/UserAgent/Keychain.pm';

build_requires 'Test::More';
requires 'Mac::Glue';
requires 'LWP::UserAgent';

use_test_base;
auto_include;
WriteAll;
