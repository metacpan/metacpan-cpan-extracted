use inc::Module::Install;

name 'Google-Ranker';
all_from 'lib/Google/Ranker.pm';

build_requires 'Test::More';

requires 'Google::Search';
requires 'Scalar::Util';
requires 'Carp';

auto_install;

WriteAll;

