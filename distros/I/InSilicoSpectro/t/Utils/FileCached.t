#!/usr/bin/env perl
use strict;

use Test::More tests => 1;
use File::Basename;
use Data::Serializer;

use InSilicoSpectro::Utils::FileCached;

ok( 1 == 1 , 'null test');

{
  package DummyClass;
  our (@ISA);
  @ISA = qw(InSilicoSpectro::Utils::FileCached);
  our $cptTot=0;
  sub new{
    my ($pkg, $h)=@_;
    my $dvar=$pkg->SUPER::new();
    $dvar->{cpt}=$cptTot++;
    bless $dvar, $pkg;
    return $dvar;
  }
  use overload '""' => \&toSummaryString;
  sub toSummaryString{
    my $self=shift;
    return "cpt=$self->{cpt}";
  }
}

$InSilicoSpectro::Utils::FileCached::REMOVE_TEMP_FILES=0;
InSilicoSpectro::Utils::FileCached::verbose(1);
InSilicoSpectro::Utils::FileCached::queueMaxSize(nbobj=>10);

my @list;
foreach (0..20){
  push @list, DummyClass->new();
}

foreach my $d (@list){
  print "".$d->FC_getme."\n";
}
