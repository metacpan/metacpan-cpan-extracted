use inc::Module::Install;

name        'Function-Composition';
all_from    'lib/Function/Composition.pm';
repository  'https://github.com/shelling/function-composition';
license     'MIT';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_include;
WriteAll;
