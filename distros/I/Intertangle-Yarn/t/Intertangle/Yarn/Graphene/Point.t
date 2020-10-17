#!/usr/bin/env perl

use Test::Most tests => 5;
use Modern::Perl;
use Intertangle::Yarn::Graphene;

subtest "Create point" => sub {
	ok my $p = Intertangle::Yarn::Graphene::Point->new( x => 1, y => -0.5 ), 'create Point';
	cmp_deeply $p->x, num(1), 'x dimension';
	cmp_deeply $p->y, num(-0.5), 'y dimension';
};

subtest "Equality operator" => sub {
	my $p = Intertangle::Yarn::Graphene::Point->new( x => 1, y => -0.5 );

	is $p, [1, -0.5], 'equality operator overload';
};

subtest "Modify point coordinate" => sub {
	ok my $p = Intertangle::Yarn::Graphene::Point->new(), 'create Point';
	my $tol = 1E-5;

	cmp_deeply $p->x, num(0, $tol), 'x dimension is zero by default';

	$p->x(4.2);

	cmp_deeply $p->x, num(4.2, $tol), 'x dimension is changed';
};

subtest "Point stringify" => sub {
	my $p = Intertangle::Yarn::Graphene::Point->new( x => 1, y => -0.5 );

	is "$p", "[x: 1, y: -0.5]";
};

subtest "HashRef" => sub {
	my $p = Intertangle::Yarn::Graphene::Point->new( x => 1, y => -0.5 );

	is_deeply $p->to_HashRef, {
		x => 1,
		y => -0.5,
	}, 'converted to HashRef';
};

done_testing;
