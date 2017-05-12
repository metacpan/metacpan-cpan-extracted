use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::ReadmeMarkdownFromPod;

name     'List-Rubyish-Circular';
all_from 'lib/List/Rubyish/Circular.pm';
name     'List-Rubyish-Circular';
author   'Kentaro Kuribayashi, <kentarok@cpan.org>';
license  'MIT';

readme_markdown_from 'lib/List/Rubyish/Circular.pm';

requires qw(
    parent
    List::Rubyish
);

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More' => 0.96; # done_testing, subtest

author_tests('xt');
auto_include_deps;

repository 'http://github.com/kentaro/list-rubyish-circular';
bugtracker 'http://github.com/kentaro/list-rubyish-circular/issues';

WriteAll;
