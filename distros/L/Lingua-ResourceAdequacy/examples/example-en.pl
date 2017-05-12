#!/usr/bin/perl

use strict;
use warnings;

# This example is issued from Ninova et al. 2005.

use Lingua::ResourceAdequacy;

my $RA = Lingua::ResourceAdequacy->new();

my @words = ("he", "has", "fixed", "the", "operating", "system");
my $RA2 = Lingua::ResourceAdequacy->new("word_list" => \@words);

my @terms = ("system", "operating system");

my $RA3 = Lingua::ResourceAdequacy->new("word_list" => \@words, 
					      "term_list" => \@terms);
$RA3->term_list_stats();
$RA3->print_term_list_stats();
$RA3->word_list_stats();
$RA3->print_word_list_stats();

my @DUP = ("system", "operating", "system");
my @UP = ("system", "operating", "system");

$RA3->set_DUP_list(\@DUP);

$RA3->set_UP_list(\@UP);

$RA3->UP_list_stats();
$RA3->print_UP_list_stats();

$RA3->DUP_list_stats();
$RA3->print_DUP_list_stats();

$RA3->AdequacyMeasures();
$RA3->print_AdequacyMeasures();

