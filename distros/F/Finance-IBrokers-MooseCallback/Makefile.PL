use 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'Finance-IBrokers-MooseCallback';
all_from 'lib/Finance/IBrokers/MooseCallback.pm';
author   q{Doug Spencer <forhire99@gmail.com>};
license  'artistic2';

perl_version 5.006;

tests_recursive('t');

resources (
   #homepage   => 'http://yourwebsitehere.com',
   #IRC        => 'irc://irc.perl.org/#Finance-IBrokers-MooseCallback',
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   #repository => 'git://github.com/Doug Spencer/Finance-IBrokers-MooseCallback.git',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-IBrokers-MooseCallback',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
   'MooseX::Declare' => 0,
   'Finance::InteractiveBrokers::TWS' => 0,
   'Data::Dumper' => 0,
   'Time::HiRes::Value' => 0,
   'Date::Manip' => 0,
   'MooseX::Types' => 0,
   'MooseX::Types::Moose' => 0,
   'MooseX::Types::URI' => 0,
   'Time::HiRes::Value' => 0,

);

requires (
   #'ABC'              => 1.6,
   #'Foo::Bar::Module' => 5.0401,
);

install_as_cpan;
auto_install;
WriteAll;
