#!/usr/bin/env perl
use strict;
use Carp;

BEGIN{
  use File::Basename;
  push @INC, (dirname $0).'/../../lib';
}

use InSilicoSpectro;
use InSilicoSpectro::InSilico::AASequence;
use InSilicoSpectro::InSilico::Sequence;
use InSilicoSpectro::InSilico::MassCalculator;

eval{
  InSilicoSpectro::init();
  my $test = shift;

  if ($test == 1){
    # Test 1, basic instantiations
    my $seq = new InSilicoSpectro::InSilico::AASequence(AC=>'myAC', sequence=>'ARGHIAMDEAD');
    print $seq;

    my $seq2=new InSilicoSpectro::InSilico::AASequence($seq);
    print "\nClone:\n$seq2";

    my $seq3=new InSilicoSpectro::InSilico::Sequence(AC=>'myAC', sequence=>'ARGHIAMDEAD');
    my $seq4=new InSilicoSpectro::InSilico::AASequence($seq3);
    print "\nClone2:\n$seq4\n";
  }

  if ($test == 2){
    # Test 2, instanciate from a Bio::Perl object
    require Bio::Perl;
    my $bpseq = Bio::Perl::get_sequence('swiss', 'ROA1_HUMAN') || die("cannot access [ROA1_HUMAN] on remote DB");
    my $seq = InSilicoSpectro::InSilico::AASequence->new($bpseq);
    print $seq;
    print "Length=",$seq->getLength(),"\n";
  }

  if ($test == 3){
    # Test 3, modifications
    my $protein = 'MCTMACTKGIPRKQWWEMMKPCKADFCV';
    my $modif =   '::Cys_CAM::Oxidation::::::::::::::Oxidation:::::::::::';
    my $seq = InSilicoSpectro::InSilico::AASequence->new(sequence=>$protein, modif=>$modif);
    print "Modifications set by a string\n";
    print $seq->sequence(), "\n", modifToString($seq->modif()), "\nMass=", $seq->getMass(), "\n";
    $seq = InSilicoSpectro::InSilico::AASequence->new(sequence=>$protein);
    $seq->modifAt(length($protein)+1, 'BIOT');
    $seq->modifAt(1, 'Oxidation_M');
    $seq->modifAt(4, 'Oxidation');
    print "\nModifications set at specific positions\n";
    print $seq->sequence(), "\n", modifToString($seq->modif()), "\nMonoisotopic mass=", $seq->getMass();
    setMassType(1);
    print ", average mass=", $seq->getMass(), "\n";
  }
};
if ($@){
  carp($@);
}
