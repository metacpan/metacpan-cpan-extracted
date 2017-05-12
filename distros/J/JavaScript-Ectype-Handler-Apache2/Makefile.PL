use inc::Module::Install;

name     'JavaScript-Ectype-Handler-Apache2';
all_from 'lib/JavaScript/Ectype/Handler/Apache2.pm';
author   q{Daichi Hiroki <hirokidaichi@gmail.com>};
license  'perl';

build_requires 'Test::More';
build_requires 'Test::MockObject';
for(qw/
    HTTP::Date
    JavaScript::Ectype
    mod_perl2
/){
    requires $_;
}
auto_install;

WriteAll;

