use strict;
use warnings;
use List::Pairwise ':all';
use Test::More;

plan tests => 4*3*2 unless $::NO_PLAN && $::NO_PLAN;

# mapp, same as map (always list context)
{
	my ($c, $facit);
	map { sub { $facit = wantarray }->() } 1;
	mapp { sub { $c = wantarray }->() } 1, 1;
	is($c, $facit, 'void mapp, same context as void map');
	is($c, 1, 'void mapp, list context');
}
{
	my ($c, $facit);
	scalar map { sub { $facit = wantarray }->() } 1;
	scalar mapp { sub { $c = wantarray }->() } 1, 1;
	is($c, $facit, 'scalar mapp, same context as scalar map');
	is($c, 1, 'scalar mapp, list context');
}
{
	my ($c, $facit);
	() = map { sub { $facit = wantarray }->() } 1;
	() = mapp { sub { $c = wantarray }->() } 1, 1;
	is($c, $facit, 'list mapp, same context as list map');
	is($c, 1, 'list mapp, list context');
}

# grepp, same as grep (always scalar context)
{
	my ($c, $facit);
	grep { sub { $facit = wantarray }->() } 1;
	grepp { sub { $c = wantarray }->() } 1, 1;
	is($c, $facit, 'void grepp, same context as void grep');
	is($c, '', 'void grepp, scalar context');
}
{
	my ($c, $facit);
	scalar grep { sub { $facit = wantarray }->() } 1;
	scalar grepp { sub { $c = wantarray }->() } 1, 1;
	is($c, $facit, 'scalar grepp, same context as scalar grep');
	is($c, '', 'scalar grepp, scalar context');
}
{
	my ($c, $facit);
	() = grep { sub { $facit = wantarray }->() } 1;
	() = grepp { sub { $c = wantarray }->() } 1, 1;
	is($c, $facit, 'list grepp, same context as list grep');
	is($c, '', 'void grepp, scalar context');
}

# lastp, same as grep (always scalar context)
{
	my ($c, $facit);
	grep { sub { $facit = wantarray }->() } 1;
	lastp { sub { $c = wantarray }->() } 1, 1;
	is($c, $facit, 'void lastp, same context as void lastp');
	is($c, '', 'void lastp, scalar context');
}
{
	my ($c, $facit);
	scalar grep { sub { $facit = wantarray }->() } 1;
	scalar lastp { sub { $c = wantarray }->() } 1, 1;
	is($c, $facit, 'scalar lastp, same context as scalar lastp');
	is($c, '', 'scalar lastp, scalar context');
}
{
	my ($c, $facit);
	() = grep { sub { $facit = wantarray }->() } 1;
	() = lastp { sub { $c = wantarray }->() } 1, 1;
	is($c, $facit, 'list lastp, same context as list lastp');
	is($c, '', 'list lastp, scalar context');
}

# firstp, same as grep (always scalar context)
{
	my ($c, $facit);
	grep { sub { $facit = wantarray }->() } 1;
	firstp { sub { $c = wantarray }->() } 1, 1;
	is($c, $facit, 'void firstp, same context as void firstp');
	is($c, '', 'void firstp, scalar context');
}
{
	my ($c, $facit);
	scalar grep { sub { $facit = wantarray }->() } 1;
	scalar firstp { sub { $c = wantarray }->() } 1, 1;
	is($c, $facit, 'scalar firstp, same context as scalar firstp');
	is($c, '', 'scalar firstp, scalar context');
}
{
	my ($c, $facit);
	() = grep { sub { $facit = wantarray }->() } 1;
	() = firstp { sub { $c = wantarray }->() } 1, 1;
	is($c, $facit, 'list firstp, same context as list firstp');
	is($c, '', 'list firstp, scalar context');
}