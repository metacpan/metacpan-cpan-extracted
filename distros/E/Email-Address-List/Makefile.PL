use inc::Module::Install;
all_from 'lib/Email/Address/List.pm';
readme_from 'lib/Email/Address/List.pm';
perl_version_from 'lib/Email/Address/List.pm';

requires 'Email::Address';

test_requires 'Test::More';
test_requires 'JSON';

sign;
WriteAll;
