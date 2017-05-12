#!/usr/bin/env perl
use strict;
use Carp;

BEGIN{
  use File::Basename;
  push @INC, (dirname $0).'/../../lib';
}

use InSilicoSpectro;
use InSilicoSpectro::InSilico::AASequence;
use InSilicoSpectro::InSilico::Peptide;
use InSilicoSpectro::InSilico::MassCalculator;

eval{
  InSilicoSpectro::init();
  my $test = shift;

  if ($test == 1){
    # test 1, basic instanciation from a parent protein
    my $seq = new InSilicoSpectro::InSilico::AASequence(AC=>'myAC', sequence=>'
MKWVTFISLL FLFSSAYSRG VFRRDAHKSE VAHRFKDLGE ENFKALVLIA FAQYLQQCPF
EDHVKLVNEV TEFAKTCVAD ESAENCDKSL HTLFGDKLCT VATLRETYGE MADCCAKQEP
ERNECFLQHK DDNPNLPRLV RPEVDVMCTA FHDNEETFLK KYLYEIARRH PYFYAPELLF
FAKRYKAAFT ECCQAADKAA CLLPKLDELR DEGKASSAKQ RLKCASLQKF GERAFKAWAV
ARLSQRFPKA EFAEVSKLVT DLTKVHTECC HGDLLECADD RADLAKYICE NQDSISSKLK
ECCEKPLLEK SHCIAEVEND EMPADLPSLA ADFVESKDVC KNYAEAKDVF LGMFLYEYAR
RHPDYSVVLL LRLAKTYETT LEKCCAAADP HECYAKVFDE FKPLVEEPQN LIKQNCELFE
QLGEYKFQNA LLVRYTKKVP QVSTPTLVEV SRNLGKVGSK CCKHPEAKRM PCAEDYLSVV
LNQLCVLHEK TPVSDRVTKC CTESLVNRRP CFSALEVDET YVPKEFNAET FTFHADICTL
SEKERQIKKQ TALVELVKHK PKATKEQLKA VMDDFAAFVE KCCKADDKET CFAEEGKKLV
AASQAALGL', readingFrame=>2);
    my $pept = new InSilicoSpectro::InSilico::Peptide(parentProtein=>$seq, start=>15, end=>27, aaBefore=>substr($seq->sequence(), 14, 1), aaAfter=>substr($seq->sequence(), 28, 1), nmc=>3);
    print "$pept (reading frame ", $pept->readingFrame(), ")\n";
  }

  if ($test == 2){
    # Test 2, basic direct instanciation with modifications and mass computation
    my $pept = new InSilicoSpectro::InSilico::Peptide(sequence=>'ACGTMHIMGTK', modif=>'::Cys_CAM::::::Oxidation::::');
    print "$pept (", modifToString($pept->modif(), $pept->getLength()), ", ",$pept->getModifType(),")\nLength=", $pept->getLength(), "\nMonoisotopic mass=", $pept->getMass();
    setMassType(1);
    print ", average mass=", $pept->getMass(), "\n";
  }

  if ($test == 3){
    # Test 3, PMF style
    my $pept = new InSilicoSpectro::InSilico::Peptide(sequence=>'ACGTMHIMGTK', modif=>[1,'Cys_CAM', 1,'Oxidation']);
    print "$pept (", modifToString($pept->modif(), $pept->getLength()), ", ",$pept->getModifType(),")\nLength=", $pept->getLength(), "\nMonoisotopic mass=", $pept->getMass();
    setMassType(1);
    print ", average mass=", $pept->getMass(), "\n";
  }
};
if ($@){
  carp($@);
}
