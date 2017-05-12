use inc::Module::Install;

name     'Format-Human-Bytes';
all_from 'lib/Format/Human/Bytes.pm';
author   'Sebastian Willing <sewi@cpan.org>';
license  'perl';

test_requires 'Test::More';

auto_install;

WriteAll;

