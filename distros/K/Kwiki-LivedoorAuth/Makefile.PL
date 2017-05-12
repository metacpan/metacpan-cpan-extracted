use inc::Module::Install;
name 'Kwiki-LivedoorAuth';
all_from 'lib/Kwiki/LivedoorAuth.pm';

requires $_ for (qw/ WebService::Livedoor::Auth URI::Escape /);

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
