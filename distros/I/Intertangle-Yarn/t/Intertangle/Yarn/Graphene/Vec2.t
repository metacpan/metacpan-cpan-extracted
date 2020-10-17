#!/usr/bin/env perl

use Test::Most tests => 4;
use Modern::Perl;
use Intertangle::Yarn::Graphene;

subtest "Create Vec2" => sub {
	ok my $v = Intertangle::Yarn::Graphene::Vec2->new( x => 1, y => -0.5 ), 'create Vec2';
	cmp_deeply $v->x, num(1), 'x component';
	cmp_deeply $v->y, num(-0.5), 'y component';
};

subtest "Equality operator" => sub {
	my $v = Intertangle::Yarn::Graphene::Vec2->new( x => 1, y => -0.5 );

	is $v, [1, -0.5], 'equality operator overload';
};

subtest "Vec2 stringify" => sub {
	my $v = Intertangle::Yarn::Graphene::Vec2->new( x => 1, y => -0.5 );

	is "$v", "[x: 1, y: -0.5]";
};

subtest "HashRef" => sub {
	my $p = Intertangle::Yarn::Graphene::Vec2->new( x => 1, y => -0.5 );

	is_deeply $p->to_HashRef, {
		x => 1,
		y => -0.5,
	}, 'converted to HashRef';
};

done_testing;

