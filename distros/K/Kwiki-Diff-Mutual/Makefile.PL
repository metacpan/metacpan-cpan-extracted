use inc::Module::Install;
name 'Kwiki-Diff-Mutual';
all_from 'lib/Kwiki/Diff/Mutual.pm';

requires $_ for (qw/ Kwiki Kwiki::Diff Algorithm::Diff String::Diff /);

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
