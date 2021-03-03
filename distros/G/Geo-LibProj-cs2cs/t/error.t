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


subtest 'unsupported params' => sub {
	plan tests => 3;
	@crs = ('+init=epsg:4326' => '+init=epsg:32630');
	
	throws_ok {
		Geo::LibProj::cs2cs->new(@crs, {-E => ''});
	} qr/\bunsupported\b/i, 'unsupported -E';
	throws_ok {
		Geo::LibProj::cs2cs->new(@crs, {-t => ''});
	} qr/\bunsupported\b/i, 'unsupported -t';
	throws_ok {
		Geo::LibProj::cs2cs->new(@crs, {-v => ''});
	} qr/\bunsupported\b/i, 'unsupported -v';
};


subtest 'transform usage' => sub {
	plan tests => 4;
	@crs = ('+init=epsg:4326' => '+init=epsg:4326');
	
	lives_ok { $c = {}; $c = Geo::LibProj::cs2cs->new(@crs); } 'new cs2cs';
	$c->{format_in} = '%f';
	$c->{call} = ['cat', '-'];
	lives_ok { $p = 0; $p = $c->transform( [undef, undef, undef, undef] ); } 'undef transform lives';
	is_deeply $p, [0, 0, 0], 'undef transform result';
	
	throws_ok {
		$c->transform( [undef, undef], [undef, undef] );
	} qr/\bprohibited\b.*\bcontext\b/i, 'list in scalar context';
};


my $old_cmd = $Geo::LibProj::cs2cs::CMD;
subtest 'child failure' => sub {
	plan skip_all => 'test requires IPC' if $INC{'Geo/LibProj/FFI.pm'};
	plan tests => 8;
	
	$Geo::LibProj::cs2cs::CMD = 'false';
	throws_ok { Geo::LibProj::cs2cs->version; } qr/\bexited with status 1\b/, 'exit status';
	$Geo::LibProj::cs2cs::CMD = '/dev/null';
	throws_ok { Geo::LibProj::cs2cs->version; } qr/\bfailed to execute\b/, 'failed to execute';
	
	$Geo::LibProj::cs2cs::CMD = 'true';
	lives_ok { $p = Geo::LibProj::cs2cs->version; } 'true lives';
	is $p, '', 'version no output';
	lives_ok { $c = 0; $c = Geo::LibProj::cs2cs->new(undef, undef); } 'new cs2cs true';
	throws_ok {
		$c->transform( [undef, undef] );
	} qr/\bAssertion failed\b/i, 'transform no output';
	
	$c->{call} = ['echo', '12 34'];
	throws_ok {
		$c->transform( [undef, undef] );
	} qr/\bAssertion failed\b/i, 'transform unexpected num output';
	$c->{call} = ['echo', 'ab cd'];
	throws_ok {
		$c->transform( [undef, undef] );
	} qr/\bAssertion failed\b/i, 'transform unexpected str output';
	
};
$Geo::LibProj::cs2cs::CMD = $old_cmd;


done_testing;
