#!perl
use strict;
use warnings;
use lib qw(lib);

use Geo::LibProj::cs2cs;
my $proj_available;
BEGIN {
	use IPC::Run3 qw(run3);
	my $bin = Geo::LibProj::cs2cs->_cmd;
	eval { run3 [$bin, '-lp'], \undef, \undef, \undef };
	$proj_available = ! $@ && $? == 0;
	unless ($proj_available) {
		print qq{1..0 # SKIP cs2cs not found (is PROJ installed?)\n};
		exit;
	}
}


use Test::More 0.96 tests => 6 + 1;
use Test::Exception;
use Test::Warnings;


my ($c, $p, @p);
my (@crs, @pts);


subtest 'version' => sub {
	plan tests => 7;
	my $v;
	
	lives_ok { $v = 0; $v = Geo::LibProj::cs2cs->version; } 'get version (class)';
	lives_and { like $v, qr/^\d+\.\d/; } 'version syntax (class)';
	lives_and { no warnings 'numeric'; ok $v >= 4; } 'version plausible (class)';
	
	lives_ok { $c = bless {cmd=>'cs2cs'}, 'Geo::LibProj::cs2cs'; } 'create instance';
	lives_ok { $v = 0; $v = $c->version; } 'get version (instance)';
	lives_and { like $v, qr/^\d+\.\d/; } 'version syntax (instance)';
	lives_and { no warnings 'numeric'; ok $v >= 4; } 'version plausible (instance)';
	
	diag "PROJ $v (" . Geo::LibProj::cs2cs->_cmd . ")";
};


subtest 'transform synopsis' => sub {
	plan tests => 7;
	@crs = ('+init=epsg:25833' => '+init=epsg:4326');
	
	lives_ok { $c = 0; $c = Geo::LibProj::cs2cs->new(@crs); } 'new cs2cs fwd';
	lives_ok { $p = 0; $p = $c->transform( [500_000, 6094_791] ); } 'transform 1 lives';
	lives_ok { $p->[1] = sprintf "%.6g", $p->[1]; } 'transform 1 result round-off';
	is_deeply $p, [15, 55, 0], 'transform 1 result';
	
	lives_ok { $c = 0; $c = Geo::LibProj::cs2cs->new(@crs, {-f=>'%.6g'}); } 'new cs2cs fwd -f';
	@pts = ([500_000, 6094_791, 200], [504_760, 6093_880]);
	lives_ok { @p = 0; @p = $c->transform( @pts ); } 'transform 2 lives';
	is_deeply \@p, [[15, 55, 200],[15.0744, 54.9918, 0]], 'transform 2 result';
};


subtest 'transform dms' => sub {
	plan tests => 12;
	@crs = ('+init=epsg:4326' => '+init=epsg:25833');
	
	lives_ok { $c = 0; $c = Geo::LibProj::cs2cs->new(@crs, {-f=>'%.0f',-r=>''}); } 'new cs2cs in';
	lives_ok { $p = 0; $p = $c->transform( [q(54d59'30"N), q(15d4'28"E)] ); } 'in lives';
	is_deeply $p, [504763, 6093867, 0], 'in result';
	
	@crs = reverse @crs;
	lives_ok { $c = 0; $c = Geo::LibProj::cs2cs->new(@crs, {-f=>undef}); } 'new cs2cs out';
	lives_ok { $p = 0; $p = $c->transform( [504763, 6093867] ); } 'out lives';
	is_deeply $p, [q(15d4'27.995"E), q(54d59'30.012"N), 0], 'out result';
	
	lives_ok { $c = 0; $c = Geo::LibProj::cs2cs->new(@crs, {-f=>undef,-w=>1}); } 'new cs2cs out -w';
	lives_ok { $p = 0; $p = $c->transform( [504763, 6093867] ); } 'out lives -w';
	is_deeply $p, [q(15d4'28"E), q(54d59'30"N), 0], 'out result -w';
	
	lives_ok { $c = 0; $c = Geo::LibProj::cs2cs->new(@crs, {-f=>undef,-W=>2}); } 'new cs2cs out -W';
	lives_ok { $p = 0; $p = $c->transform( [504763.1, 6093867.0] ); } 'out lives -W';
	is_deeply $p, [q(15d04'28.00"E), q(54d59'30.01"N), 0], 'out result -W';
};


subtest 'transform error' => sub {
	plan tests => 2;
	@crs = ('+init=epsg:4326' => '+init=epsg:32630');
	
	lives_ok { $p = 0; $p = $c->transform( ['Inf', '-Inf'] ); } 'inf transform lives';
	lives_and { is_deeply [$p->[0], $p->[1]], ['*', '*'] } 'inf transform result';
};


subtest 'child failure stderr' => sub {
	plan tests => 3;
	lives_ok { $c = {}; $c = Geo::LibProj::cs2cs->new(undef, undef); } 'new cs2cs';
	$c->{call} = [ $c->{call}->[0], '-l-' ];
	throws_ok {
		$c->transform( [undef, undef] );
	} qr/\binvalid\b/i, 'invalid option';
	ok $c->{stderr}, 'stderr';
};


subtest 'problematic floats' => sub {
	plan tests => 3;
	# hexadecimal %a format isn't fully supported by cs2cs
	# certain floats may cause problems (possibly length-dependent)
	@pts = (
		[ 5.634748, -3.666786 ],  # 0x1.689fb61p+2, -0x1.d5593e6p+1
		[ 5.634740, -3.666780 ],  # 0x1.689f948p+2, -0x1.d5590c1p+1
	);
	lives_ok { $c = 0; $c = Geo::LibProj::cs2cs->new('+init=epsg:4326' => '+init=epsg:3395', {-r=>'', -f=>'%.9g'}); } 'new cs2cs';
	lives_ok { @p = 0; @p = $c->transform(@pts); } 'transform lives';
	is_deeply \@p, [
		[-408184.750, 624078.416, 0],
		[-408184.082, 624077.527, 0],
	], 'result valid' or diag 'possible cause: $FORMAT_IN="%a"';
};


done_testing;
