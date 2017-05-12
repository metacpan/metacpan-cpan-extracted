#!/usr/bin/perl -w
use strict;

use Test::More;
use Devel::Platform::Info::Mac;

eval "use Test::MockObject::Extends";
plan skip_all => "Test::MockObject::Extends required for these tests" if $@;

plan tests => 29;

my $macInfo = Devel::Platform::Info::Mac->new();
my $mock = Test::MockObject::Extends->new($macInfo);
$mock->set_series('_command', '', '', '', '', '');
my $info = $macInfo->get_info();
is($info->{osname}, 'Mac');
is($info->{osflag}, $^O);

$mock->set_series('_command', 'Darwin', '10.3', 'PPC', 'Darwin 1', 'uname -a');
$info = $macInfo->get_info();

is($info->{osname}, 'Mac');
is($info->{osflag}, $^O);
is($info->{oslabel}, 'OS X');
is($info->{codename}, 'Panther');
is($info->{osvers}, '10.3');
is($info->{archname}, 'PPC');
is($info->{is32bit}, 1);
is($info->{is64bit}, 0);
is($info->{kernel}, 'Darwin 1');

$mock->set_series('_command', 'Darwin', '10.4.11', 'powerpc', 'Darwin Kernel Version 8.11.0: Wed Oct 10 18:26:00 PDT 2007; root:xnu-792.24.17~1/RELEASE_PPC', 'Darwin somewhere.co.uk 8.11.0 Darwin Kernel Version 8.11.0: Wed Oct 10 18:26:00 PDT 2007; root:xnu-792.24.17~1/RELEASE_PPC Power Macintosh powerpc');
$info = $macInfo->get_info();

is($info->{osname}, 'Mac');
is($info->{osflag}, $^O);
is($info->{oslabel}, 'OS X');
is($info->{codename}, 'Tiger');
is($info->{osvers}, '10.4.11');
is($info->{archname}, 'powerpc');
is($info->{is32bit}, 1);
is($info->{is64bit}, 0);
is($info->{kernel}, 'Darwin Kernel Version 8.11.0: Wed Oct 10 18:26:00 PDT 2007; root:xnu-792.24.17~1/RELEASE_PPC');

$mock->set_series('_command', 'Darwin', '10.4.11', 'i386', 'Darwin Kernel Version 8.11.1: Wed Oct 10 18:23:28 PDT 2007; root:xnu-792.25.20~1/RELEASE_I386', 'Darwin somehost 8.11.1 Darwin Kernel Version 8.11.1: Wed Oct 10 18:23:28 PDT 2007; root:xnu-792.25.20~1/RELEASE_I386 i386 i386');
$info = $macInfo->get_info();

is($info->{osname}, 'Mac');
is($info->{osflag}, $^O);
is($info->{oslabel}, 'OS X');
is($info->{codename}, 'Tiger');
is($info->{osvers}, '10.4.11');
is($info->{archname}, 'i386');
is($info->{is32bit}, 1);
is($info->{is64bit}, 0);
is($info->{kernel}, 'Darwin Kernel Version 8.11.1: Wed Oct 10 18:23:28 PDT 2007; root:xnu-792.25.20~1/RELEASE_I386');

# use Data::Dumper;
# print Dumper($info);
