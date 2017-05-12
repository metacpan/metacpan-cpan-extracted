use inc::Module::Install;
name 'Markdown-Foswiki';
all_from 'lib/Markdown/Foswiki.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
