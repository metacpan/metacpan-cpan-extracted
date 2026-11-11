use v5.40;
use Test2::V1 -ipP;

use lib 't/lib';
use Gears::Test::Router;

################################################################################
# This tests whether the sigil-based router matching works, using cases taken
# from Kelp
################################################################################

my $r = Gears::Test::Router->new(
	location_impl => 'Gears::Router::Location::SigilMatch',
	pattern_separator => '^',
);

subtest 'router should produce valid locations' => sub {
	$r->clear;

	my $loc1 = $r->add('^test');
	my $loc2 = $loc1->add('^deep');

	is $loc1->pattern, '^test', 'bridge ok';
	is $loc2->pattern, '^test^deep', 'location ok';

	is $loc2->build, '^test^deep', 'build method works';
};

subtest 'router should use the chosen separator' => sub {
	$r->clear;

	my $loc1 = $r->add('^');
	my $loc2 = $loc1->add('^');

	is $loc1->pattern, '^', 'bridge ok';
	is $loc2->pattern, '^', 'location ok';
};

subtest 'router should match locations' => sub {
	$r->clear;

	my $t1 = $r->add('^test1');
	my $t1l1 = $t1->add('^1');
	my $t1l2 = $t1->add('^11');
	my $t1l3 = $t1->add('^12');

	my $t2 = $r->add('^test2');
	my $t2l1 = $t2->add('^');
	my $t2l2 = $t2->add('^');
	my $t2l3 = $t2->add('^1');

	my $t2f = $r->add('^test2^1');

	# NOTE: bridges are matched even if there are no matching routes underneath them
	_match('^test', [], 'bad match ok');
	_match('^test1', [[$t1]], 'match bridge ok');
	_match('^test12', [], 'match bridge prefix ok');
	_match('^test1^1', [[$t1, $t1l1]], 'match full path ok');
	_match('^test1^123', [[$t1]], 'match too long path ok');

	# NOTE: routes should always be matched in the order of declaration and nesting
	_match('^test2', [[$t2, $t2l1, $t2l2]], 'match empty subpath ok');
	_match('^test2^1', [[$t2, $t2l3], $t2f], 'match across locations ok');
};

subtest 'router should match locations with placeholders' => sub {
	$r->clear;

	my $t1 = $r->add('^a');
	my $t1l1 = $t1->add('^>b');
	my $t2 = $r->add('^c^?d');

	_match('^', [], 'empty match ok');
	_match('^a', [[$t1, $t1l1]], 'no slurpy match ok');
	_match('^a^', [[$t1, $t1l1]], 'trailing separator match ok');
	_match('^a^abc', [[$t1, $t1l1]], 'placeholder filled match ok');
	_match('^a^abc^def', [[$t1, $t1l1]], 'slurpy placeholder filled with separator match ok');
	_match('^c', [$t2], 'optional placeholder not filled match ok');
	_match('^c^d', [$t2], 'optional placeholder not filled match ok');
	_match('^c^d^ef', [], 'optional placeholder filled with separator match ok');
	_match('^ab', [], 'bad match ok');
};

subtest 'router should build locations' => sub {
	$r->clear;

	my $t1 = $r->add('^a');
	my $t1l2 = $t1->add('^>b');

	is $t1l2->build(), '^a', 'built without placeholder ok';
	is $t1l2->build(b => 'test'), '^a^test', 'built with placeholder ok';
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

