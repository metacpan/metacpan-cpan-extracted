#!perl
use strict;
use warnings;
use lib qw(lib);

use Geo::LibProj::cs2cs;
my $proj_available;


use Test::More 0.96 tests => 3 + 1;
use Test::Exception;
use Test::Warnings;


my ($c, $p, @p);
my (@crs, @pts);


subtest 'argument order' => sub {
	plan tests => 3;
	@crs = ('+init=epsg:4326' => '+proj=merc +lon_0=110');
	my $params = {-f=>'%.0f'};
	my ($c1, $c2);
	lives_ok { $c1 = Geo::LibProj::cs2cs->new(@crs, $params); } 'new cs2cs post';
	lives_ok { $c2 = Geo::LibProj::cs2cs->new($params, @crs); } 'new cs2cs pre';
	is_deeply $c1, $c2, 'reverse arg order ok';
};


subtest 'special params' => sub {
	plan tests => 12;
	@crs = ('+init=epsg:4326' => '+init=epsg:32630');
	
	lives_ok { $c = 0; $c = Geo::LibProj::cs2cs->new(@crs, {-d=>5, -f=>'%.7f'}); } 'new cs2cs -d -f';
	ok grep(m/^%\.5f$/, @{$c->{call}}), 'converted -d';
	ok ! grep(m/^-d$/, @{$c->{call}}), 'removed -d';
	
	lives_ok { $c = 0; $c = Geo::LibProj::cs2cs->new(@crs, {-d=>5, -f=>undef}); } 'new cs2cs -d';
	ok ! grep(m/^-f$/, @{$c->{call}}), 'not converted -d';
	ok grep(m/^-d$/, @{$c->{call}}), 'not removed -d';
	
	lives_ok { $c = 0; $c = Geo::LibProj::cs2cs->new(@crs, {-f=>undef,-w=>1}); } 'new cs2cs -w';
	ok grep(m/^-w1$/, @{$c->{call}}), 'converted -w';
	ok ! grep(m/^-w$/, @{$c->{call}}), 'removed -w';
	
	lives_ok { $c = 0; $c = Geo::LibProj::cs2cs->new(@crs, {-f=>undef,-W=>2}); } 'new cs2cs -W';
	ok grep(m/^-W2$/, @{$c->{call}}), 'converted -W';
	ok ! grep(m/^-W$/, @{$c->{call}}), 'removed -W';
};


subtest 'transform pass-through simulation' => sub {
	plan skip_all => 'test requires IPC' if $INC{'Geo/LibProj/FFI.pm'};
	plan tests => 8;
	@crs = ('+init=epsg:4326' => '+init=epsg:32630');
	@p = ('5dE', '40dN', '9e+9999', bless {}, 'xxx');
	lives_ok { $c = {}; $c = Geo::LibProj::cs2cs->new(@crs); } 'new cs2cs';
	$c->{format_in} = '%f';
	$c->{call} = ['cat', '-'];
	
	lives_ok { $p = 0; $p = $c->transform( \@p ); } 'transform dms lives';
	is $p->[0], $p[0], 'transform x result';
	is $p->[1], $p[1], 'transform y result';
	like $p->[2], qr/Inf/i, 'transform z result';
	is ref($p->[3]), ref($p[3]), 'transform aux result';
	
	@pts = ([15, 55, 200], [15.0744, 54.9918, 0]);
	lives_ok { @p = 0; @p = $c->transform( @pts ); } 'transform deg lives';
	is_deeply \@p, \@pts, 'transform deg result';
};


done_testing;
