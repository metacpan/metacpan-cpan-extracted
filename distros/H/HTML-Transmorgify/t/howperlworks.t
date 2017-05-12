#!/usr/bin/perl -I.

use strict;
use Test::More qw(no_plan);
use warnings;

my $finished = 0;

END { ok($finished, "finished"); }


our $var;

sub one
{
	my $first = "first value";
	local($var) = \$first;
	two();
}

sub two
{
	my $second = "2nd";
	local($var) = \$second;
	three();
}

sub three
{
	my $x = $var;
	sub { $x };
}

my $t = one();

is(${&$t}, "2nd", "old locals are retained");


package A;

use Test::More;
use strict;
use warnings;

our $foo = 'old';
BEGIN {
	require Exporter;
	our @ISA = qw(Exporter);
	our @EXPORT = qw($foo check);
}

sub check
{
	is($foo, "new", "override foo");
}

package B;

use Test::More;
use strict;
use warnings;

BEGIN { A->import };

{
	local($foo) = 'new';
	check();
}

is($foo, 'old', "revert");



sub ret { return };
sub retlist { return() };

my @reta = ret();
my $reta = ret();
my @retlist = retlist();
my $retlist = retlist();

is(scalar(@reta), 0, "plain return retuns empty list");
is($reta, undef, "empty return sends undef");
is(scalar(@retlist), 0, "empty lists gives empty list");
is($retlist, undef, "empty lists undef in scalar");

$finished = 1;

