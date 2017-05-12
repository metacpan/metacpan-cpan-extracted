sub author_tests         {}
sub readme_from          {}
sub auto_set_repository  {}

use inc::Module::Install;

name        'HTML-ValidationRules';
all_from    'lib/HTML/ValidationRules.pm';
readme_from 'lib/HTML/ValidationRules.pm';

auto_set_repository;

requires 'autodie';
requires 'HTML::Parser';
requires 'Scalar::Util::Numeric';

recommends 'FormValidator::Simple';
recommends 'FormValidator::Lite';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';

test_requires 'Test::More' => 0.96; # done_testing, subtest
test_requires 'Test::Differences';
test_requires 'Test::Requires';
test_requires 'Test::Name::FromLine';
test_requires 'Exporter::Lite';

author_tests('xt');
WriteAll;
