#!/usr/bin/env perl

use Test::Most tests => 3;
use Intertangle::Yarn::Types qw(Point Vec2 Size);

subtest "Point" => sub {
	my $p = Point->coerce( [ 2, 7 ] );
	is $p->x, 2, 'x';
	is $p->y, 7, 'y';
};

subtest "Vec2" => sub {
	my $p = Vec2->coerce( [ 8, 9 ] );
	is $p->x, 8, 'x';
	is $p->y, 9, 'y';
};

subtest "Size" => sub {
	my $s = Size->coerce( [ 10, 20 ] );
	is $s->width, 10, 'width';
	is $s->height, 20, 'height';
};

done_testing;
