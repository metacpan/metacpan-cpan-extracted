use inc::Module::Install;
name 'Hash-Lazy';
all_from 'lib/Hash/Lazy.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';

auto_include;
WriteAll;
