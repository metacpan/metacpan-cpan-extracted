use inc::Module::Install;

name           'File-Path-Stderr';

all_from       'lib/File/Path/Stderr.pm';

# any version of Test::More will do
build_requires 'Test::More' => 0;

license 'perl';
githubmeta;
author_tests('xt');

WriteAll;
