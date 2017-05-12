use inc::Module::Install;

use 5.008008;
name     'Devel-Leak-Cb';
all_from 'lib/Devel/Leak/Cb.pm';
version   my $v = '0.04';
author   'Mons Anderson <mons@cpan.org>';
license  'perl';

build_requires 'Test::More';
build_requires 'lib::abs', '0.90';

requires 'common::sense' => '2';
requires 'Devel::Declare' => '0.005011';
recommends 'Sub::Identify';
recommends 'Sub::Name';
recommends 'Devel::Refcount';
recommends 'Devel::FindRef';

provides 'Devel::Leak::Cb' => {
	version => $v,
	file    => 'lib/Devel/Leak/Cb.pm',
};

auto_install;

WriteAll;

