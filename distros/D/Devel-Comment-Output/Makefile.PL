use inc::Module::Install;

name 'Devel-Comment-Output';
all_from 'lib/Devel/Comment/Output.pm';

requires 'parent';
requires 'Symbol';
requires 'Scalar::Util';
requires 'Tie::Handle';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::Requires';
test_requires 'File::Temp';

auto_set_repository;
auto_include_deps;

readme_markdown_from 'lib/Devel/Comment/Output.pm';

if ($Module::Install::AUTHOR) {
    require File::Copy;
    File::Copy::mv('README.mkdn', 'README.md');
}

WriteAll;
