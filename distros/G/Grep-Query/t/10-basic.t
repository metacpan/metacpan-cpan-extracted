use strict;
use warnings;

use Grep::Query qw(qgrep);
use Grep::Query::FieldAccessor;

my @miscDelims;
push(@miscDelims, chr($_)) for (33..39, 42..59, 61, 63..90, 92, 94..122, 124, 126);

use Test::More;

plan(tests => 25 + scalar(@miscDelims));

is(scalar(qgrep('true')), 0, "query empty plain set (non-OO)");
is(scalar(qgrep('TRUE')), 0, "query empty plain set (non-OO)");
is(scalar(qgrep('false')), 0, "query empty plain set (non-OO)");
is(scalar(qgrep('FALSE')), 0, "query empty plain set (non-OO)");

is(scalar(qgrep('defined', 1, undef, 2, undef)), 2, "query set with two defined values (non-OO)");

is(scalar(qgrep('size==(3)', 'aaa', undef, 'b', 'cccc', 'ddd')), 2, "query set with two values of size 3 (non-OO)");

my @typetestlist =
(
	{ fee => [1, undef, 3] },
	{ fee => [4, 5, 6] },
	{ fee => [7, 8, 9] },
);
is(scalar(qgrep('fee.type(ARRAY) && fee->[1].type(scalar)', undef, @typetestlist)), 2, "query set with two values of size 3 (non-OO)");

is(scalar(qgrep('REGEXP(.*)')), 0, "query empty plain set (non-OO)");

my $q1 = 'REGEXP(.*)';
my $gq1 = Grep::Query->new($q1);
is($gq1->getQuery(), $q1, 'verify query text');
is(scalar($gq1->qgrep()), 0, "query empty plain set");

my $gq2 = Grep::Query->new('field1.REGEXP(.*)');
is(scalar($gq2->qgrep(undef)), 0, "query empty fielded set");

my $fa = Grep::Query::FieldAccessor->new({ field1 => sub { die("never executed") } });
is(scalar($gq2->qgrep($fa)), 0, "query empty fielded set with explicit field accessor");

ok(defined(Grep::Query->new('REGEXP(.*) AND EQ(42) OR NE(15) AND GT(9) OR GE(98) AND LT(65) OR LT(32)')), "UPPERCASING");

ok(defined(Grep::Query->new('regexp(.*) and eq(42) or ne(15) and gt(9) or ge(98) and lt(65) or lt(32)')), "LOWERCASING");

ok(defined(Grep::Query->new('==(42) or !=(15) and >(9) or >=(98) and <(65) or <=(32)')), "NUMERICAL");

ok(defined(Grep::Query->new('==(42)')), "delimiters ()");
ok(defined(Grep::Query->new('=={42}')), "delimiters {}");
ok(defined(Grep::Query->new('==[42]')), "delimiters []");
ok(defined(Grep::Query->new('==<42>')), "delimiters <>");
 
ok(defined(Grep::Query->new("eq${_} ${_}")), "same delimiter ${_}") foreach (@miscDelims);

ok(defined(Grep::Query->new('foo.==(42) OR foo.==(68)')), "one field multiple times");

ok(defined(Grep::Query->new('/**/ true')), "Empty comment");
ok(defined(Grep::Query->new('/* before */ true')), "Comment before");
ok(defined(Grep::Query->new('true /* after */')), "Comment after");
ok(defined(Grep::Query->new('/* before */ true /* after */')), "Comments before and after");

my $qWithComments = <<'Q';
	true
	/* first part */
	or
	/* second part
	   which is no
	   multiple lines */
	false
Q
ok(defined(Grep::Query->new($qWithComments)), "Multiline comment");
