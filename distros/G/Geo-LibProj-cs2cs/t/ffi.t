#!perl
use strict;
use warnings;
use lib qw(lib);

use Geo::LibProj::cs2cs;


use Test::More;
use Test::Exception;
use Test::Warnings qw(warning);

plan skip_all => "Geo::LibProj::FFI loaded (can't mock)" if $INC{'Geo/LibProj/FFI.pm'};
unless ($INC{'Geo/LibProj/FFI.pm'}) {
	package Geo::LibProj::FFI;
	our ($ctx, $pj);
	sub proj_context_create { $ctx }
	sub proj_create_crs_to_crs { $pj }
	sub proj_context_use_proj4_init_rules { }
	sub proj_context_destroy { die unless shift }
	sub proj_destroy { die unless shift }
	sub proj_info { __PACKAGE__ }  # for ->version
	sub version { 'mock' }
	sub _trans { $_[2] }
}

plan tests => 7 + 1;


my $c = bless {}, 'Geo::LibProj::cs2cs';


subtest 'special params' => sub {
	plan tests => 9;
	$INC{'Geo/LibProj/FFI.pm'} = 1;
	$c->{ffi} = 0;
	$c->{ffi_warn} = 1;
	lives_ok { $c->_special_params({XS => undef}) } 'XS undef lives';
	ok $c->{ffi}, 'XS undef enables';
	ok ! $c->{ffi_warn}, 'XS undef no warnings';
	$c->{ffi} = 0;
	$c->{ffi_warn} = 0;
	lives_ok { $c->_special_params({XS => 1}) } 'XS 1 lives';
	ok $c->{ffi}, 'XS 1 enables';
	ok $c->{ffi_warn}, 'XS 1 warnings';
	$c->{ffi} = 1;
	$c->{ffi_warn} = 1;
	lives_ok { $c->_special_params({XS => 0}) } 'XS 0 lives';
	ok ! $c->{ffi}, 'XS 0 disables';
	ok ! $c->{ffi_warn}, 'XS 0 no warnings';
	delete $INC{'Geo/LibProj/FFI.pm'};
};


sub ffi_init {
	plan tests => 24;
	my $w;
	my @crs = ('dummy source' => 'dummy target');
	
	$c->{ffi} = 0;
	lives_ok { $w = warning { $c->_ffi_init(@crs) }} 'unloaded lives';
	if ($c->{ffi_warn}) {
		like $w, qr/\bGeo::LibProj::FFI\b/, 'unloaded warning'
			or diag 'got warning(s): ', explain $w;
	}
	else {
		is_deeply $w, [], 'unloaded no warning'
			or diag 'got warning(s): ', explain $w;
	}
	ok ! $c->{ffi}, 'unloaded disables';
	
	$Geo::LibProj::FFI::ctx = 0;
	$c->{ffi} = 1;
	lives_ok { $w = warning { $c->_ffi_init(@crs) }} 'context lives';
	if ($c->{ffi_warn}) {
		like $w, qr/\bproj_context_create\b/, 'context warning'
			or diag 'got warning(s): ', explain $w;
	}
	else {
		is_deeply $w, [], 'context no warning'
			or diag 'got warning(s): ', explain $w;
	}
	ok ! $c->{ffi}, 'context disables';
	
	$Geo::LibProj::FFI::ctx = 1;
	$Geo::LibProj::FFI::pj = 0;
	$c->{ffi} = 1;
	lives_ok { $w = warning { $c->_ffi_init(@crs) }} 'proj lives';
	if ($c->{ffi_warn}) {
		like $w, qr/\bproj_create_crs_to_crs\b/, 'proj warning'
			or diag 'got warning(s): ', explain $w;
	}
	else {
		is_deeply $w, [], 'proj no warning'
			or diag 'got warning(s): ', explain $w;
	}
	ok ! $c->{ffi}, 'proj disables';
	
	$Geo::LibProj::FFI::ctx = 1;
	$Geo::LibProj::FFI::pj = 1;
	$c->{ffi} = 1;
	lives_ok { $w = warning { $c->_ffi_init(@crs, {-I => '6'}) }} 'parameter';
	if ($c->{ffi_warn}) {
		like $w, qr/\bcontrol parameters\b/, 'parameter warning'
			or diag 'got warning(s): ', explain $w;
	}
	else {
		is_deeply $w, [], 'parameter no warning'
			or diag 'got warning(s): ', explain $w;
	}
	ok ! $c->{ffi}, 'parameter disables';
	
	$c->{ffi} = 1;
	lives_ok { $w = warning { $c->_ffi_init(@crs, {-f => '%.2f'}) }} '-f custom';
	if ($c->{ffi_warn}) {
		like $w, qr/\bcontrol parameters\b/, '-f custom warning'
			or diag 'got warning(s): ', explain $w;
	}
	else {
		is_deeply $w, [], '-f custom no warning'
			or diag 'got warning(s): ', explain $w;
	}
	ok ! $c->{ffi}, '-f custom disables';
	
	$c->{ffi} = 1;
	lives_ok { $w = warning { $c->_ffi_init(@crs, {-f => $Geo::LibProj::cs2cs::FORMAT_OUT}) }} '-f default lives';
	is_deeply $w, [], '-f default no warning'
		or diag 'got warning(s): ', explain $w;
	ok $c->{ffi}, '-f default enables';
	
	$c->{ffi} = 1;
	lives_ok { $w = warning { $c->_ffi_init(@crs, {-f => undef}) }} '-f undef lives';
	is_deeply $w, [], '-f undef no warning'
		or diag 'got warning(s): ', explain $w;
	ok $c->{ffi}, '-f undef enables';
	
	$c->{ffi} = 1;
	lives_ok { $w = warning { $c->_ffi_init(@crs) }} 'ok lives';
	is_deeply $w, [], 'ok no warning'
		or diag 'got warning(s): ', explain $w;
	ok $c->{ffi}, 'ok enables';
}


subtest 'ffi init quiet' => sub {
	$c->{ffi_warn} = 0;
	ffi_init();
};


subtest 'ffi init warn' => sub {
	$c->{ffi_warn} = 1;
	ffi_init();
};


subtest 'transform' => sub {
	plan tests => 5;
	$c->{ffi} = 1;
	my ($p, @p);
	my $p0 = [-12.3, 34.5, -56.7, 78.9];
	my @p1 = ($p0, [47, 11, 0], [0, 0, undef, {n => rand}]);
	lives_ok { $p = $c->transform($p0) } 'transform scalar lives';
	is_deeply $p, $p0, 'transform scalar';
	lives_ok { @p = $c->transform(@p1) } 'transform list lives';
	is_deeply \@p, \@p1, 'transform list';
	throws_ok { $p = $c->transform(@p1) } qr/\blist\b.* prohibited in scalar context\b/, 'transform scalar with list dies';
};


subtest 'version' => sub {
	plan tests => 1;
	$c->{ffi} = 1;
	lives_and { is $c->version, 'mock' } 'version mocked';
};


subtest 'xs' => sub {
	plan tests => 1;
	$c->{ffi} = rand;
	lives_and { is $c->xs, $c->{ffi} } 'xs';
};


subtest 'destroy' => sub {
	plan tests => 3;
	$c->{ffi_pj} = 1;
	$c->{ffi_ctx} = 1;
	lives_ok { $c->DESTROY } 'both lives';
	$c->{ffi_ctx} = 0;
	lives_ok { $c->DESTROY } 'pj lives';
	$c->{ffi_pj} = 0;
	lives_ok { $c->DESTROY } 'neither lives';
};


done_testing;
