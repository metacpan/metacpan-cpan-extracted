sub author_tests         {}
sub readme_markdown_from {}
sub auto_set_repository  {}

use inc::Module::Install;

name     'Hash-Compact';
author   'Kentaro Kuribayashi, <kentarok@cpan.org>';
license  'Perl';

all_from             'lib/Hash/Compact.pm';
readme_markdown_from 'lib/Hash/Compact.pm';

repository 'https://github.com/kentaro/perl-hash-compact';
bugtracker 'https://github.com/kentaro/perl-hash-compact/issues';
auto_set_repository;

requires 'Scalar::Util';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More' => 0.96; # done_testing, subtest
author_tests('xt');

WriteAll;
