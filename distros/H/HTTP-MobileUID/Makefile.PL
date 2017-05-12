use inc::Module::Install;
name 'HTTP-MobileUID';
all_from 'lib/HTTP/MobileUID.pm';

build_requires 'Test::More';
requires 'Class::Data::Accessor' => 0.03;
requires 'HTTP::MobileAgent'     => 0.26;
use_test_base;
auto_install;
WriteAll;
