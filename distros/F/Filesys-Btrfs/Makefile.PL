use inc::Module::Install;

name     'Filesys-Btrfs';
all_from 'lib/Filesys/Btrfs.pm';
author   q{Nikolay Martynov <kolya@cpan.org>};
license  'perl';

requires 'Carp';
requires 'IPC::Cmd';
requires 'Path::Class';

test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Test::Deep';
test_requires 'Try::Tiny';
test_requires 'autodie';
test_requires 'IPC::System::Simple';
test_requires 'File::Temp';

auto_install;

WriteAll;

