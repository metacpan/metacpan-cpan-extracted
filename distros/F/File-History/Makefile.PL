use inc::Module::Install;
name 'File-History';
all_from 'lib/File/History.pm';

requires $_ for qw(
    File::ReadBackwards
    Class::Accessor::Fast
    IO::File
);

build_requires 'Test::More';
build_requires 'Path::Class';
build_requires 'Path::Class::File';
build_requires 'Path::Class::Dir';
build_requires 'Path::Class::Entity';
use_test_base;
auto_include;
WriteAll;
