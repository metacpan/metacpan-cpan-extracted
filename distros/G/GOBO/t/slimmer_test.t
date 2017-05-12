#!/usr/bin/perl -w
# tests for the slimdown script

use strict;
use FileHandle;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use GOBO::Parsers::OBOParser;

use Test::More;
plan tests => 44;

my $verbose = $ENV{GO_VERBOSE} || 0;

my $status;
# 1
$status = `perl bin/go-slimdown.pl -i t/data/obofile.obo -s test_goslim -o t/slimmer_test_results.obo 2>&1 1>/dev/null`;
like( $status, qr/Error: /, "Checking go-slimdown.pl with invalid input");

# 2
$status = `perl bin/go-slimdown.pl -i t/data/obo_file.obo -s test_goslim 2>&1 1>/dev/null`;
like( $status, qr/Error: /, "Checking go-slimdown.pl with no output");

# 3
$status = `perl bin/go-slimdown.pl -i t/data/obo_file.obo -o t/slimmer_test_results.obo 2>&1 1>/dev/null`;
like( $status, qr/Error: /, "Checking go-slimdown.pl with no slim");

# 4
$status = `perl bin/go-slimdown.pl -i t/data/obo_file.obo -s test_goslim -b t/data/myslimfile 2>&1 1>/dev/null`;
like( $status, qr/Error: /, "Checking go-slimdown.pl with incorrectly specified output");


# goslim not in file
# 5
$status = `perl bin/go-slimdown.pl -i t/data/obo_file.obo -s goslim_monster -o t/slimmer_test_results.obo 2>&1 1>/dev/null`;
like( $status, qr/Error: /, "Checking go-slimdown.pl with invalid subset");

# 6
$status = system("perl", qw( bin/go-slimdown.pl -i t/data/obo_file.obo -s test_goslim -o t/slimmer_test_results.obo) );
ok($status == 0, "Checking go-slimdown.pl with valid args");

die "go-slimdown.pl exited funny: $?" unless $status == 0;

## read in the graph, check it is ok
my $parser = new GOBO::Parsers::OBOParser(file=>"t/slimmer_test_results.obo");
$parser->parse;

# 7
cmp_ok(testme($parser->graph, 1), "==", 1, "Checking slimdown results");
system("rm", "t/slimmer_test_results.obo");

die ("Did not remove t/slimmer_test_results.obo properly!") if -e "t/slimmer_test_results.obo";

# 8
# OK, let's try a different slim now...
$status = system("perl", qw( bin/go-slimdown.pl -i t/data/obo_file.obo -s test_next_goslim -o t/slimmer_test_results.obo) );
ok($status == 0, "Checking go-slimdown.pl with valid args -i t/data/obo_file.obo -s test_next_goslim -o t/slimmer_test_results.obo");

die "go-slimdown.pl exited funny: $?" unless $status == 0;

## read in the graph, check it is ok
undef $parser;
$parser = new GOBO::Parsers::OBOParser(file=>"t/slimmer_test_results.obo");
$parser->parse;

# 9
cmp_ok(testme($parser->graph, 2), "==", 1, "Checking slimdown results");
system("rm", "t/slimmer_test_results.obo");

die ("Did not remove t/slimmer_test_results.obo properly!") if -e "t/slimmer_test_results.obo";

my $args = {
1 => [ qw(-s test_next_goslim -s test_goslim) ],
2 => [ qw(-s test_next_goslim test_goslim) ],
3 => [ '-a' ],
4 => [ qw(-r test) ],
5 => [ qw(-r test.+goslim) ],
};

# 10 - 44
# 7 tests per arg
foreach my $a (values %$args)
{	my $cmd;
	# invalid inputs
	# xxx, combined, no output
	$cmd = 'perl bin/go-slimdown.pl -i t/data/obo_file.obo ' . join(" ", @$a) . " --combined -b t/obo_file_SLIM_NAME.obo 2>&1 1>/dev/null";
	$status = `$cmd`;

	like( $status, qr/Error: /, "Checking go-slimdown.pl with invalid params");

	# xxx, not combined, no basefile
	$cmd = 'perl bin/go-slimdown.pl -i t/data/obo_file.obo ' . join(" ", @$a) . " -o t/slimmer_test_results.obo 2>&1 1>/dev/null";
	$status = `$cmd`;

	like( $status, qr/Error: /, "Checking go-slimdown.pl with invalid params");

	# valid inputs
	$status = system("perl", qw( bin/go-slimdown.pl -i t/data/obo_file.obo -b t/obo_file_SLIM_NAME.obo), @$a );

	ok($status == 0, "Checking go-slimdown.pl with args -i t/data/obo_file.obo -b t/obo_file_SLIM_NAME.obo " . join(" ", @$a) );

	die "go-slimdown.pl exited funny: $?" unless $status == 0;

	## read in the graph, check it is ok
	undef $parser;
	$parser = new GOBO::Parsers::OBOParser(file=>"t/obo_file_test_goslim.obo");
	$parser->parse;

	cmp_ok(testme($parser->graph, 1), "==", 1, "Checking slimdown results");

	## read in the graph, check it is ok
	undef $parser;
	$parser = new GOBO::Parsers::OBOParser(file=>"t/obo_file_test_next_goslim.obo");
	$parser->parse;

	cmp_ok(testme($parser->graph, 2), "==", 1, "Checking slimdown results");

	system("rm", "t/obo_file_test_goslim.obo");
	system("rm", "t/obo_file_test_next_goslim.obo");

	# now test a combination of slims
	$status = system("perl", qw( bin/go-slimdown.pl -i t/data/obo_file.obo -o t/slimmer_test_results.obo --combined) , @$a );

	ok($status == 0, "Checking go-slimdown.pl with valid args -i t/data/obo_file.obo -o t/slimmer_test_results.obo --combined " . join(" ", @$a) );

	die "go-slimdown.pl exited funny: $?" unless $status == 0;

	## read in the graph, check it is ok
	undef $parser;
	$parser = new GOBO::Parsers::OBOParser(file=>"t/slimmer_test_results.obo");
	$parser->parse;

	cmp_ok(testme($parser->graph, 3), "==", 1, "Checking slimdown results");

	system("rm", "t/slimmer_test_results.obo");
	die ("Did not remove t/slimmer_test_results.obo properly!") if -e "t/slimmer_test_results.obo";

}

exit(0);



=cut
GO:0000001 is_a GO:0000008
GO:0000001 part_of GO:0000008
GO:0000001 regulates GO:0000008
GO:0000002 is_a GO:0000006
GO:0000002 is_a GO:0000007
GO:0000003 part_of GO:0000007
GO:0000004 is_a GO:0000012
GO:0000004 positively_regulates GO:0000015
GO:0000004 negatively_regulates GO:0000016
GO:0000005 regulates GO:0000008
GO:0000006 is_a GO:0000009
GO:0000007 part_of GO:0000011
GO:0000008 negatively_regulates GO:0000010
GO:0000009 is_a GO:0000010
GO:0000010 is_a GO:0000018
GO:0000011 is_a GO:0000010
GO:0000012 is_a GO:0000013
GO:0000013 is_a GO:0000014
GO:0000014 is_a GO:0000018
GO:0000015 part_of GO:0000014
GO:0000016 is_a GO:0000014
GO:0000017 is_a GO:0000019
GO:0000018 is_a GO:0000019
GO:0000021 is_a GO:0000019
GO:0000022 is_a GO:0000021
GO:0000023 is_a GO:0000022
GO:0000024 is_a GO:0000023
GO:0000024 part_of GO:0000025
GO:0000025 part_of GO:0000019

negatively_regulates is_a regulates
positively_regulates is_a regulates

GS terms:
GO:0000001
GO:0000002
GO:0000003
GO:0000004
GO:0000005
GO:0000006
GO:0000007
GO:0000010
GO:0000014
GO:0000015
GO:0000019
GO:0000024
GO:0000025

rlns we should therefore have:
GO:0000001 is_a GO:0000008 negatively_regulates GO:0000010       neg regs
GO:0000001 part_of GO:0000008 negatively_regulates GO:0000010    regs
GO:0000001 regulates GO:0000008 negatively_regulates GO:0000010  no rln
GO:0000002 is_a GO:0000006                                       is a
GO:0000002 is_a GO:0000007                                       is a
GO:0000002 is_a GO:0000007 part_of GO:0000011 is_a GO:0000010    part of
GO:0000003 part_of GO:0000007                                    part of
GO:0000004 is_a GO:0000012 is_a GO:0000013 is_a GO:0000014       is a
GO:0000004 pos_regs GO:0000015                                   pos regs
GO:0000004 neg_regulates GO:0000016 is_a GO:0000014              neg regs
GO:0000005 regulates GO:0000008 negatively_regulates GO:0000010  no rln
GO:0000006 is_a GO:0000010                                       is a
GO:0000007 part_of GO:0000011 is_a GO:0000010                    part of
GO:0000010 is_a GO:0000018 is_a GO:0000019                       is a
GO:0000014 is_a GO:0000018 is_a GO:0000019                       is a
GO:0000015 part_of GO:0000014                                    part of
GO:0000024 is_a ... is_a GO:0000021 is_a GO:0000019              is a
GO:0000024 part_of GO:0000025                                    part of
GO:0000025 part_of GO:0000019                                    part of

negatively_regulates is_a regulates
positively_regulates is_a regulates

=cut

sub testme {
	my $g = shift;
	my $n = shift;  # test number

my $answers;

$answers->{1}{"GO:0000001"}{negatively_regulates}{"GO:0000010"} = 1,
#$answers->{"GO:0000001"}{regulates}{"GO:0000010"} = 1,
$answers->{1}{"GO:0000002"}{is_a}{"GO:0000006"} = 1;
$answers->{1}{"GO:0000002"}{is_a}{"GO:0000007"} = 1;
$answers->{1}{"GO:0000002"}{part_of}{"GO:0000010"} = 1;
$answers->{1}{"GO:0000003"}{part_of}{"GO:0000007"} = 1;
$answers->{1}{"GO:0000004"}{is_a}{"GO:0000014"} = 1;
$answers->{1}{"GO:0000004"}{positively_regulates}{"GO:0000015"} = 1;
# $answers->{"GO:0000004"}{regulates}{"GO:0000015"} = 1;
$answers->{1}{"GO:0000004"}{negatively_regulates}{"GO:0000014"} = 1;
# $answers->{"GO:0000004"}{regulates}{"GO:0000014"} = 1;
$answers->{1}{"GO:0000006"}{is_a}{"GO:0000010"} = 1;
$answers->{1}{"GO:0000007"}{part_of}{"GO:0000010"} = 1;
$answers->{1}{"GO:0000010"}{is_a}{"GO:0000019"} = 1;
$answers->{1}{"GO:0000014"}{is_a}{"GO:0000019"} = 1;
$answers->{1}{"GO:0000015"}{part_of}{"GO:0000014"} = 1;
$answers->{1}{"GO:0000024"}{is_a}{"GO:0000019"} = 1;
$answers->{1}{"GO:0000024"}{part_of}{"GO:0000025"} = 1;
$answers->{1}{"GO:0000025"}{part_of}{"GO:0000019"} = 1;
#$answers->{negatively_regulates}{is_a}{regulates} = 1;
#$answers->{positively_regulates}{is_a}{regulates} = 1;

$answers->{2}{"GO:0000001"}{regulates}{"GO:0000008"} = 1,
$answers->{2}{"GO:0000001"}{is_a}{"GO:0000008"} = 1,
$answers->{2}{"GO:0000001"}{part_of}{"GO:0000008"} = 1,
$answers->{2}{"GO:0000001"}{negatively_regulates}{"GO:0000019"} = 1,
$answers->{2}{"GO:0000002"}{is_a}{"GO:0000019"} = 1,
$answers->{2}{"GO:0000002"}{part_of}{"GO:0000019"} = 1,
$answers->{2}{"GO:0000003"}{part_of}{"GO:0000019"} = 1,
$answers->{2}{"GO:0000005"}{regulates}{"GO:0000008"} = 1,
$answers->{2}{"GO:0000008"}{negatively_regulates}{"GO:0000019"} = 1,
$answers->{2}{"GO:0000013"}{is_a}{"GO:0000019"} = 1,
$answers->{2}{"GO:0000021"}{is_a}{"GO:0000019"} = 1,


$answers->{3}{"GO:0000001"}{regulates}{"GO:0000008"} = 1,
$answers->{3}{"GO:0000001"}{is_a}{"GO:0000008"} = 1,
$answers->{3}{"GO:0000001"}{part_of}{"GO:0000008"} = 1,
$answers->{3}{"GO:0000001"}{negatively_regulates}{"GO:0000010"} = 1,
$answers->{3}{"GO:0000002"}{is_a}{"GO:0000006"} = 1;
$answers->{3}{"GO:0000002"}{is_a}{"GO:0000007"} = 1;
$answers->{3}{"GO:0000002"}{part_of}{"GO:0000010"} = 1;
$answers->{3}{"GO:0000003"}{part_of}{"GO:0000007"} = 1;
$answers->{3}{"GO:0000004"}{is_a}{"GO:0000013"} = 1;
$answers->{3}{"GO:0000004"}{positively_regulates}{"GO:0000015"} = 1;
$answers->{3}{"GO:0000004"}{negatively_regulates}{"GO:0000014"} = 1;
$answers->{3}{"GO:0000005"}{regulates}{"GO:0000008"} = 1,
$answers->{3}{"GO:0000006"}{is_a}{"GO:0000010"} = 1;
$answers->{3}{"GO:0000007"}{part_of}{"GO:0000010"} = 1;
$answers->{3}{"GO:0000008"}{negatively_regulates}{"GO:0000010"} = 1,
$answers->{3}{"GO:0000010"}{is_a}{"GO:0000019"} = 1;
$answers->{3}{"GO:0000013"}{is_a}{"GO:0000014"} = 1,
$answers->{3}{"GO:0000014"}{is_a}{"GO:0000019"} = 1;
$answers->{3}{"GO:0000015"}{part_of}{"GO:0000014"} = 1;
$answers->{3}{"GO:0000021"}{is_a}{"GO:0000019"} = 1,
$answers->{3}{"GO:0000024"}{is_a}{"GO:0000021"} = 1;
$answers->{3}{"GO:0000024"}{part_of}{"GO:0000025"} = 1;
$answers->{3}{"GO:0000025"}{part_of}{"GO:0000019"} = 1;

	my $summary;
	my $ans;
	map {
		my $t = $_;
		map {
			my $r = $_;
			map {
				$ans->{$t}{$r}{$_} = 1
				} keys %{$answers->{$n}{$t}{$r}};
			} keys %{$answers->{$n}{$t}};
		} keys %{$answers->{$n}};

	foreach my $t (sort { $a->id cmp $b->id } @{$g->terms})
	{	#my @links = @{ $infeng->get_inferred_target_links($t) };
		my @links = @{ $g->get_outgoing_links($t) };

#		print STDERR "links for " . $t->id . ": " . Dumper( \@links );

		foreach (sort { $a->target->id cmp $b->target->id } @links)
		{
			print STDERR "\nnode: " . $_->node->id . ", target: " . $_->target->id . "\n" if $verbose;

			if ($ans->{$_->node->id}
				&& $ans->{$_->node->id}{$_->relation->id}
				&& $ans->{$_->node->id}{$_->relation->id}{$_->target->id} )
			{	# found the correct answer :D
			#	ok(1, "Checking ". $_->node->id . " " . $_->relation->id . " " . $_->target->id);

				print STDERR $_->node->id .": looking for ". join(" or ", keys %{$ans->{$_->node->id}} ) . ", found " . $_->relation->id . "\n" if $verbose;

				delete $ans->{$_->node->id}{$_->relation->id}{$_->target->id};

				if (! keys %{$ans->{$_->node->id}{$_->relation->id}})
				{	delete $ans->{$_->node->id}{$_->relation->id};
				}

				if (! keys %{$ans->{$_->node->id}})
				{	delete $ans->{$_->node->id};
				}
			}
			else
			{	# shouldn't have found a relation
				print STDERR $_->node->id .": found " . $_->relation->id . " " . $_->target->id . ", incorrect!\n" if $verbose;
			#	ok(0, $_->node->id .": incorrectly inferred relation " . $_->relation->id . " (none expected)");
				$summary->{$_->node->id}{$_->relation->id}{$_->target->id}++;
			}
		}
	}

#	ok(! keys %{$ans->}, "Checking we have no results left");

#	if ($verbose)
	if (keys %$ans || keys %$summary)
	{	if (keys %$ans)
		{	print STDERR "Missing the following inferences:\n" . Dumper($ans);
		}
		if (keys %$summary)
		{	print STDERR "Made the following incorrect inferences:\n" . Dumper($summary);
		}
		return 2;
	}
	return 1;
}
