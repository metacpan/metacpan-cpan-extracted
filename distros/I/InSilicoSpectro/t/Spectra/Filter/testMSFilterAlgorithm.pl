#!/usr/bin/env perl
use strict;
use Carp;
use Pod::Usage;
use Math::FixedPrecision;

use Test::More tests=>5;
use_ok( 'InSilicoSpectro::Spectra::Filter::MSFilter' );

=head1 NAME

testMSFilterAlgorithm.pl

=head1 DESCRIPTION

test the class MSFilterAlgorithm.pm 

=head1 COPYRIGHT

Copyright (C) 2004-2005  Geneva Bioinformatics www.genebio.com

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

Roman Mylonas, www.genebio.com

=cut


use Carp;
use File::Compare;


eval{
  my $dataDir = "testData/";
  my $xml_file= "test_algorithm.xml";
  my $file= "test_algorithm.mgf";

  my @test_name= qw(balance goodDiff waterLosses complements);


  my $iTest=undef;
  $iTest=shift @ARGV;
  $iTest = "all" unless defined $iTest;


  #loads the result data in a 2d-array
  my @result=();
  my $i=0;

  while(my $line= <DATA>){
    chomp $line;
    #a new result
    if($line=~ /result_(\d+)/){
      $i= $1;
      next;
    }

    my $float= Math::FixedPrecision->new($line);
    push @{$result[$i]}, $float;
  }


  #opens the xml and gets the filters
  use XML::Twig;


  my $twig=XML::Twig->new(twig_handlers=>{
					  '/ExpMsMsSpectrumFilter'=> sub {twig_spectrumFilter($_[0], $_[1])},
					 },
			  pretty_print=>'indented'
			 );

  #actually parse the file
  $twig->parsefile($dataDir.$xml_file) or croak "cannot parse [$dataDir.$xml_file]: $!";


  sub twig_spectrumFilter{
    my ($twig, $el)=@_;

    my $i=1;
    foreach my $twig_el ($el->get_xpath('*')) {

      if($iTest==$i or $iTest=="all"){
	
	my $format="mgf";
	my $sp=InSilicoSpectro::Spectra::MSSpectra->new(source=>$dataDir.$file, format=>$format);
	$sp->open();

	#pass the xml
	my $sf = new InSilicoSpectro::Spectra::Filter::MSFilter();
	$sf->readTwigEl($twig_el);
	$sf->filterSpectra($sp);
	
	my $ok=1;

	#go through all the tests (respectively xml-entries)
	foreach(0..$#result){

	  #need the FixedPrecision in order to compare the floating-point-values properly
	  my $float= Math::FixedPrecision->new($sf->filterValue()->[$_]);
	 
	  unless($float == $result[$i]->[$_]){
	    $ok=0;
	    fail("test $i: $test_name[$i-1]");
	    carp "#\tposition $_: expect ".$result[$i]->[$_]." instead of ".$sf->filterValue()->[$_]."\n";
	    
	    last;
	  }
	}
	
	pass("test $i: $test_name[$i-1]") if $ok;

      }

      $i++;

    }

    #free memory;
    $twig->purge;
  }




};
if ($@){
  carp($@);
}


__DATA__
result_1
0.356859186365111
0.842985118247135
0.787802242265659
0.541500051932738
1.22996093089012
1.19031318051708
0.912995289006999
0.995060796533513
1.2022827250783
1.74933885708765
1.3323854215943
1.26641604793068
1.64646872852037
1.17376354167856
0.735061230480052
1.64256322262919
1.11013900827868
1.99796037312846
0.598663734674037
1.30435000666462
1.6874544488325
0.833874386334659
2.028032323074
1.82995407922891
result_2
1.92307692307692
48.6818181818182
37.2285714285714
0.714285714285714
94.1
74.6259541984733
76.8018018018018
24.8888888888889
76.463768115942
89.6052631578947
70.392
46.7755102040816
59.827027027027
32.2258064516129
72.1363636363636
79.5060240963856
55.405529953917
53.2809523809524
8.5
89.0595238095238
97.3423423423423
72.4038461538461
76.4700460829493
37.45
result_3
0
5.93181818181818
8.45714285714286
3.42857142857143
9.05833333333333
4.46564885496183
4.73873873873874
0
9
13.2960526315789
7.096
4.77551020408163
1.72432432432432
3.51612903225806
16.9090909090909
9.71686746987952
5.15207373271889
4.28095238095238
3
6.2202380952381
12.7882882882883
12.6153846153846
3.69585253456221
4.25
result_4
0
1.11363636363636
0
0
1.61666666666667
1.13740458015267
1.38738738738739
1.55555555555556
0.72463768115942
1.97368421052632
1.032
0.469387755102041
1.36756756756757
1.25806451612903
0.636363636363636
1.81325301204819
1.02764976958525
1.48571428571429
0.625
1.81547619047619
1.41441441441441
1.34615384615385
1.36866359447005
1.18333333333333




