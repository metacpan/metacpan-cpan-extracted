#!/usr/bin/env perl

use Test::Most tests => 2;
use Modern::Perl;

use Test::Requires {
	'Data::Printer' => 0,
};
use Intertangle::Yarn::Graphene;

subtest "Test DPR for Point" => sub {
	is np(Intertangle::Yarn::Graphene::Point->new( x => 2, y => 3 ), colored => 0 ),
		'(Intertangle::Yarn::Graphene::Point) \ { x   2, y   3 }';
};

subtest "Test DPR for Size" => sub {
	is np(Intertangle::Yarn::Graphene::Size->new( width => 2, height => 3 ), colored => 0 ),
		'(Intertangle::Yarn::Graphene::Size) \ { height   3, width   2 }';
};

done_testing;
