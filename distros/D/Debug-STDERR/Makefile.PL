use inc::Module::Install;
name 'Debug-STDERR';
all_from 'lib/Debug/STDERR.pm';

requires 'constant';
requires 'Carp';
requires 'Data::Dumper';
requires 'Time::HiRes';
requires 'POSIX';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;


