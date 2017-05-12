#!/usr/bin/perl -w

use strict;
use Data::Dumper;
$| = 1;

use Test::More 'no_plan';

use List::Analyse::Sequence;

{
  my @ul = qw( foo bar baz whiz );
  my $seq = List::Analyse::Sequence->new;

  $seq->use_these_analysers( qw( List::Analyse::Sequence::Analyser::OL::Numbered ) );
  $seq->analyse( @ul );
  my ($result, $discard ) = $seq->result;
  ok( !exists $result->[0], "no result");
  ok( $discard, "discard pile" );
  isa_ok( $discard->[0], "List::Analyse::Sequence::Analyser::OL::Numbered" );
}

{
  my @ol = ( "1. foo", "2. bar", "3.baz", "4. whiz" );
  my $seq = List::Analyse::Sequence->new;
  $seq->use_these_analysers( qw( List::Analyse::Sequence::Analyser::OL::Numbered ) );
  $seq->analyse( @ol );
  my ($result, $discard ) = $seq->result;
  ok( $result, "results" );
  isa_ok( $result->[0], "List::Analyse::Sequence::Analyser::OL::Numbered" );
  ok( !exists $discard->[0], "no discard");
}
