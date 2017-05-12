use inc::Module::Install;

name     'JavaScript-Ectype';
all_from 'lib/JavaScript/Ectype.pm';
author   q{Daichi Hiroki <hirokidaichi@gmail.com>};
license  'perl';

build_requires 'Test::More';
for(qw/
    JSON
    Carp
    File::Slurp
    JavaScript::Minifier
    Class::Accessor::Fast
    Class::Data::Inheritable
    Scalar::Util
    List::Util
/){
    requires $_;
}
auto_install;

WriteAll;

