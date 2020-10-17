#!/usr/bin/env perl

use Test::Most tests => 2;
use Modern::Perl;
use Module::Load;
use Intertangle::Yarn::Graphene;

subtest "Loaded Graphene" => sub {
	can_ok 'Intertangle::Yarn::Graphene::Point', qw(new distance);
};

subtest 'Access Graphene::Point using Inline::C' => sub {
	eval { load 'Inline::C' } or do {
		my $error = $@;
		plan skip_all => "Inline::C not installed" if $error;
	};

	Inline->import( with => qw(Intertangle::Yarn::Graphene) );

	Inline->bind( C => q|
		const graphene_point_t* sv_to_graphene_point(SV* obj) {
			GValue point_gv = {0, };
			g_value_init(&point_gv, GRAPHENE_TYPE_POINT);

			gperl_value_from_sv(&point_gv, obj);

			graphene_point_t* p = (graphene_point_t*)g_value_get_boxed(&point_gv);

			return p;
		}

		float get_x(SV* obj) {
			return sv_to_graphene_point(obj)->x;
		}

		float get_y(SV* obj) {
			return sv_to_graphene_point(obj)->y;
		}
	|, ENABLE => AUTOWRAP => );

	my $point = Intertangle::Yarn::Graphene::Point->new( x => 42, y => 3 );
	is( get_x($point), $point->x, 'Got x element');
	is( get_y($point), $point->y, 'Got y element');
};

done_testing;
