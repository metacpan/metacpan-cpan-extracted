use lib '.';
use inc::Module::Install;

name('Email-Address-List');
all_from 'lib/Email/Address/List.pm';
readme_from 'lib/Email/Address/List.pm';
perl_version_from 'lib/Email/Address/List.pm';
repository('https://github.com/bestpractical/email-address-list');

requires 'Email::Address';

test_requires 'Test::More';
test_requires 'JSON';

sign;
WriteAll;
