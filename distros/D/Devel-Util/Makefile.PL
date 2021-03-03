use inc::Module::Install;

name 'Devel-Util';
all_from 'lib/Devel/Util.pm';

build_requires 'Test::More' => '0.42';

requires 'Carp';
requires 'Exporter';
requires 'Scalar::Util';
requires 'Time::HiRes';
requires 'POSIX';

WriteAll;
