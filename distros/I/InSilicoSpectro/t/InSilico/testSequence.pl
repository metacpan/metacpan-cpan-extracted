#!/usr/bin/env perl
use strict;

use Carp;

BEGIN{
  use File::Basename;
  push @INC, (dirname $0).'/../../lib';
}


use InSilicoSpectro::InSilico::Sequence;

eval{
  my $test = shift;

  if ($test == 1){
    # Test 1, basic object instanciation
    my $seq=new InSilicoSpectro::InSilico::Sequence(AC=>'myAC', sequence=>'ARGHIAMDEAD');
    print $seq;
    my $seq2=new InSilicoSpectro::InSilico::Sequence($seq);
    print "\nClone:\n$seq2\n";
  }

  if ($test == 2){
    # Test 2, instanciate from a Bio::Perl object
    require Bio::Perl;
    my $bpseq=Bio::Perl::get_sequence('swiss', 'ROA1_HUMAN') or die "cannot access [ROA1_HUMAN] on remote DB";
    my $seq=InSilicoSpectro::InSilico::Sequence->new($bpseq);
    print $seq;
    print "Length=",$seq->getLength(),"\n";
  }
};
if ($@){
  carp($@);
}
