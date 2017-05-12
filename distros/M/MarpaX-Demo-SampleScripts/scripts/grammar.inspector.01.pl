#!/usr/bin/env perl

use strict;
use diagnostics;

use Marpa::R2;

# Author: Jeffrey Kegler.

# ---------------------

my $grammar = Marpa::R2::Scanless::G->new({ source => \do {local $/; <DATA>}});
my $fmt = "%5s %-20s %-20s %s\n";
printf $fmt, 'depth', 'ruleName', 'lhsName', 'rhsNames';
foreach (@{rulesByDepth($grammar)}) {
    printf $fmt, $_->{depth}, $_->{ruleName}, $_->{lhsName}, join(' ', @{$_->{rhsNames}});
}


sub rulesByDepth {
    my ($G, $subGrammar) = @_;

    $subGrammar ||= 'G1';

    #
    # We start by expanding all ruleIds to a LHS symbol id and RHS symbol ids
    #
    my %ruleIds = ();
    foreach ($G->rule_ids($subGrammar)) {
      my $ruleId = $_;
      $ruleIds{$ruleId} = [ $G->rule_expand($ruleId, $subGrammar) ];
    }
    #
    # We ask what is the start symbol
    #
    my $startSymbolId = $G->start_symbol_id();
    #
    # We search for the start symbol in all the rules
    #
    my @queue = ();
    my %depth = ();
    foreach (keys %ruleIds) {
	my $ruleId = $_;
	if ($ruleIds{$ruleId}->[0] == $startSymbolId) {
	    push(@queue, $ruleId);
	    $depth{$ruleId} = 0;
	}
    }

    while (@queue) {
	my $ruleId = shift(@queue);
	my $newDepth = $depth{$ruleId} + 1;
	#
	# Get the RHS ids of this ruleId and select only those that are also LHS
	#
	my (undef, @rhsIds) = @{$ruleIds{$ruleId}};
	foreach (@rhsIds) {
	    my $lhsId = $_;
	    foreach (keys %ruleIds) {
		my $ruleId = $_;
		if (! exists($depth{$ruleId})) {
		    #
		    # Rule not already inserted
		    #
		    if ($ruleIds{$ruleId}->[0] == $lhsId) {
			#
			# And having an LHS id equal to one of the RHS ids we dequeued
			#
			push(@queue, $ruleId);
			$depth{$ruleId} = $newDepth;
		    }
		}
	    }
	}
    }

    my @rc = ();
    foreach (sort {$depth{$a} <=> $depth{$b}} keys %depth) {
      my $ruleId = $_;
      my ($lhsId, @rhsIds) = @{$ruleIds{$ruleId}};
      push(@rc, {ruleId   => $ruleId,
		 ruleName => $G->rule_name($ruleId),
                 lhsId    => $lhsId,
                 lhsName  => $G->symbol_name($lhsId),
                 rhsIds   => [ @rhsIds ],
                 rhsNames => [ map {$G->symbol_name($_)} @rhsIds ],
                 depth    => $depth{$ruleId}});
    }

    return \@rc;
}

__DATA__
:start ::= Script
Script ::= null1 digits1 null2 null3 digits2 null4  name => 'The Real Start!'
digits1 ::= DIGITS
digits2 ::= DIGITS
null1   ::=              name => 'Null number 1'
null2   ::=              name => 'Null number 2'
null3   ::=              name => 'Null number 3'
null4   ::=              name => 'Null number 4'
DIGITS ~ [\\d]+
WS ~ [\\s]
:discard ~ WS
