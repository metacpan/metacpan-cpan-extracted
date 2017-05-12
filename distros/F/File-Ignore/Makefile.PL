use inc::Module::Install;

name 'File-Ignore';
all_from 'lib/File/Ignore.pm';

build_requires 'Test::More';
build_requires 'Test::Lazy';

requires qw/File::Spec/;

auto_install;

WriteAll;

