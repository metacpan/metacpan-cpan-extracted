use inc::Module::Install;

name 'Hg-Lib';
license 'perl';
all_from 'lib/Hg/Lib.pm';

author_tests 'xt';

repository 'https://bitbucket.org/djerius/hg-lib';

tests_recursive;

cpanfile;

readme_from;

WriteAll;
