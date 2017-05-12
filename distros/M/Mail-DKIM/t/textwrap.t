#!/usr/bin/perl -I../lib

use strict;
use warnings;
use Test::Simple tests => 16;

use Mail::DKIM::TextWrap;

my $tw;
$tw = Mail::DKIM::TextWrap->new;
ok($tw, "new() works");

my $output = "";
my @lines;

$tw = Mail::DKIM::TextWrap->new(
		Margin => 10,
		Output => \$output,
		);
$tw->add("Mary had a little lamb, whose fleece was white as snow.\n");
$tw->finish;
my $saved1 = $output;
check_output("basic wrapping");
ok(@lines == 7, "basic wrapping got expected number of lines");

foreach ("Mary ", "had ", "a ", "little ", "lamb, ", "whose ", "fleece ",
		"was ", "white ", "as ", "snow.\n")
{
	$tw->add($_);
}
$tw->finish;
my $saved2 = $output;
check_output("basic wrapping- words added separately, space following each");
ok($saved1 eq $saved2, "same result when words added separately, space following each");

foreach ("Mary", " had", " a", " little", " lamb,", " whose", " fleece",
		" was", " white", " as", " snow.\n")
{
	$tw->add($_);
}
$tw->finish;
my $saved3 = $output;
check_output("basic wrapping- words added separately, space preceding each");
ok($saved1 eq $saved3, "same result when words added separately, space preceding each");

$tw->{Separator} = "\n  ";
$tw->add("Mary had a little lamb, whose fleece was white as snow.\n");
$tw->finish;
check_output("with second-line indent");
ok($lines[0] =~ /^Mary had a/, "first line looks ok");

$tw = Mail::DKIM::TextWrap->new(
		Margin => 10,
		Output => \$output,
		Break => qr/[\s:]/,
		);
$tw->add("apple:orange:banana:apricot:blueberry:strawberry-kiwi\n");
$tw->finish;
check_output("colon-separated list");
ok($lines[0] eq "apple:", "first line looks ok");
ok($lines[1] eq "orange:", "second line looks ok");
ok($lines[$#lines] =~ "strawberry-kiwi", "over-long word did not get split");

$tw->add(" apple : orange : apricot : kiwi \n");
$tw->finish;
check_output("colon-separated list with spaces");
ok($lines[0] =~ /^\s/, "first line begins with space");
ok($lines[$#lines] =~ /\s$/, "last line ends with space");
ok(grep(!/(^\s|\s$)/, @lines[1 .. ($#lines - 1)]), "middle lines neither begin nor end with space");

$tw = Mail::DKIM::TextWrap->new(
		Margin => 10,
		Output => \$output,
		Break => qr/[\s:]/,
		BreakBefore => qr/[:]/,
		);
$tw->add("apple:orange:banana:apricot:lime:kiwi\n");
$tw->finish;
check_output("colon-separated list, split before colons");
ok($lines[0] eq "apple", "first line looks ok");
ok($lines[1] eq ":orange", "second line looks ok");
ok($lines[$#lines] =~ /:kiwi$/, "last line looks ok");

$tw = Mail::DKIM::TextWrap->new(
		Margin => 10,
		Output => \$output,
		);
$tw->add("apple");
$tw->add("orange");
$tw->add("banana");
$tw->add("apricot");
$tw->finish;
check_output("");
ok(@lines == 1, "no wrapping took place");

$tw = Mail::DKIM::TextWrap->new(
		Margin => 10,
		Output => \$output,
		);
foreach (qw(apple orange banana apricot))
{
	$tw->add($_);
	$tw->flush;
}
$tw->finish;
check_output("");
ok(!(grep { length($_) > 10 } @lines), "no long lines");

sub check_output
{
	my ($test_name) = @_;
	@lines = split /\n/, $output;
	$output = "";

	print "# $test_name\n";
	print "# " . ('-' x $tw->{Margin}) . "\n";
	foreach my $l (@lines)
	{
		print "# $l\n";
	}
	print "# " . ('-' x $tw->{Margin}) . "\n";
}
