use v5.40;
use Test2::V1 -ipP;

use lib 't/lib';
use Gears::Test::Router;

################################################################################
# This tests whether the basic router works
################################################################################

my $r = Gears::Test::Router->new(location_impl => 'Gears::Router::Location::Match');

subtest 'router should produce valid locations' => sub {
	$r->clear;

	my $loc1 = $r->add('/test');
	my $loc2 = $loc1->add('/deep');

	is $loc1->pattern, '/test', 'bridge ok';
	is $loc2->pattern, '/test/deep', 'location ok';

	is $loc2->build, '/test/deep', 'build method works';
};

subtest 'router should match locations' => sub {
	$r->clear;

	my $t1 = $r->add('/test1');
	my $t1l1 = $t1->add('/1');
	my $t1l2 = $t1->add('/11');
	my $t1l3 = $t1->add('/12');

	my $t2 = $r->add('/test2');
	my $t2l1 = $t2->add('');
	my $t2l2 = $t2->add('/1');

	my $t2f = $r->add('/test2/1');

	# NOTE: bridges are matched even if there are no matching routes underneath them
	_match('/test', [], 'bad match ok');
	_match('/test1', [[$t1]], 'match bridge ok');
	_match('/test1/1', [[$t1, $t1l1]], 'match full path ok');
	_match('/test1/123', [[$t1]], 'match too long path ok');

	# NOTE: routes should always be matched in the order of declaration and nesting
	_match('/test2', [[$t2, $t2l1]], 'match empty subpath ok');
	_match('/test2/1', [[$t2, $t2l2], $t2f], 'match across locations ok');
};

subtest 'router should match overlapping locations' => sub {
	$r->clear;

	my $t1 = $r->add('/test1');
	my $t1l = $t1->add('/test2/test3');

	my $t2 = $r->add('/test1/test2');
	my $t2l = $t2->add('/test3');
	_match('/test1/test2/test3', [[$t1, $t1l], [$t2, $t2l]], 'match ok');
};

subtest 'router should match deeply nested locations' => sub {
	$r->clear;

	my @to_match;
	my $last = $r;
	my @list;
	my $prev;
	my $last_match = \@to_match;
	my $uri = '';

	# keep it under "deep recursion" warnings (100)
	for my $num (1 .. 95) {
		$last = $last->add("/$num");
		$prev = $last_match;
		push @list, $last;
		push $last_match->@*, [$last];
		$last_match = $last_match->[-1];

		$uri .= "/$num";
	}

	# add a random second location, to try confusing the router (must be a bridge)
	my $l2 = $r->add('/1/2/3');
	my $l2r = $l2->add('/0');

	# fix last element - not considered a bridge
	$prev->[-1] = $prev->[-1][0];

	_match($uri, [@to_match, [$l2]], 'match ok');

	my @flat_matches = $r->flat_match($uri);
	is [map { $_->location } @flat_matches],
		[map { exact_ref $_ } @list, $l2],
		'flat matches ok';
};

subtest 'flatten + match should equal flat_match' => sub {
	$r->clear;

	my $t1 = $r->add('/test');
	my $t1l1 = $t1->add('/1');
	my $t1l2 = $t1->add('/:sth');

	my $t2 = $r->add('/test/1');

	my $matches = $r->match('/test/1');
	my @flattened = $r->flatten($matches);
	my @flat_matches = $r->flat_match('/test/1');

	# convert Match objects to location references for comparison
	my @flattened_locs = map { $_->location } @flattened;
	my @flat_matches_locs = map { exact_ref $_->location } @flat_matches;

	is \@flattened_locs, \@flat_matches_locs, 'flatten + match equals flat_match';
};

done_testing;

sub _rec_map ($sub, @arr)
{
	my @new;
	foreach (@arr) {
		if (ref eq 'ARRAY') {
			push @new, [_rec_map($sub, $_->@*)];
		}
		else {
			push @new, $sub->();
		}
	}

	return @new;
}

sub _match ($route, $expected, $name)
{
	my $result = $r->match($route);
	$result->@* = _rec_map sub { $_->location }, $result->@*;
	$expected->@* = _rec_map sub { exact_ref $_ }, $expected->@*;

	is $result, $expected, $name;
}

