#!/usr/bin/env perl
use strict;
use Carp;
use Pod::Usage;
use Test::More tests=>17;
use_ok( 'InSilicoSpectro::Spectra::Filter::MSFilter' );

=head1 NAME

testMSSpectraDirectValue.pl

=head1 DESCRIPTION

test the class MSSpectraDirectValue.pm using the filter-fields intensity and peak.intensity. 


=head1 SYNOPSIS


=head1 ARGUMENTS

=over 4

=item -dummy

=head1 OPTIONS

=over 4

=item --help

=item --man

=item --verbose

=back


=head1 EXAMPLE


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


use File::Compare;
#use InSilicoSpectro::Spectra::Filter::MSFilter;
use File::Temp qw(tempfile tempdir);
use File::Basename;
use XML::SemanticDiff;

my $removeTemp= !defined $ENV{DONOTREMOVETEMP};
eval{
  my $tmpDir = File::Temp::tempdir(CLEANUP=>$removeTemp, UNLINK=>$removeTemp);
  print STDERR "tempdir is $tmpDir\n" unless $removeTemp;
  my $dataDir = dirname(__FILE__)."/testData/";
  my $iTest=1;
  # $iTest=shift @ARGV;
  # $iTest = "all" unless defined $iTest;


  my $file_out= "$tmpDir/a.mgf";
  my $format="mgf";


  #test 1-4
  my $test_file= "$dataDir/test_1-4.mgf";
  
  while($iTest<=4){

    my $file_in= "$dataDir/test_".$iTest."_result.mgf";
    my $xml_file= "$dataDir/test_$iTest.xml";

    my $sp=InSilicoSpectro::Spectra::MSSpectra->new(source=>$test_file, format=>$format);
    $sp->open();
   
    my $sf = new InSilicoSpectro::Spectra::Filter::MSFilter();
    $sf->readXml($xml_file);
    $sf->filterSpectra($sp);

    $sp->write('mgf', $file_out);


    if(compare($file_in, $file_out)){
      fail("test $iTest [$file_in] [$file_out]");
    }else{
      pass("test $iTest");
    }
    
    #unlink $file_out;
    $iTest++;
  }



  #test 5-15
  my $test_file= "$dataDir/test_5-15.mgf";
  
  while($iTest<=15){

    my $file_in= "$dataDir/test_".$iTest."_result.mgf";
    my $xml_file= "$dataDir/test_$iTest.xml";

    my $sp=InSilicoSpectro::Spectra::MSSpectra->new(source=>$test_file, format=>$format);
    $sp->open();
   
    my $sf = new InSilicoSpectro::Spectra::Filter::MSFilter();
    $sf->readXml($xml_file);
    $sf->filterSpectra($sp);

    $sp->write('mgf', $file_out);


    if(compare($file_in, $file_out)){
      fail("test $iTest [$file_in] [$file_out]");
    }else{
      pass("test $iTest");
    }
    
    #unlink $file_out;
    $iTest++;
  }



  # test 16

  use InSilicoSpectro::Spectra::MSRun;

  my $file_out= "$tmpDir/out.16.idj.xml";
  my $file_in="$dataDir/test_16_result.idj.xml";
  my $format="idj";
  my $xml_file= "$dataDir/test_$iTest.xml";
  my $test_file= "$dataDir/test_16.idj.xml";


  my $sr=InSilicoSpectro::Spectra::MSRun->new();
  $sr->readIDJ($test_file);

  my $sf = new InSilicoSpectro::Spectra::Filter::MSFilter();
  $sf->readXml($xml_file);
  $sf->filterSpectra($sr);

  #write to disk
  my $outFile;
  open ($outFile, ">$file_out") or croak "cannot open file $file_out: $!\n";
  $sr->write('idj', $outFile);
  close $outFile;

  #compare the spectra or the files
  my $diff = XML::SemanticDiff->new();
  ok(! $diff->compare($file_in, $file_out), "xml/diff [$file_in] [$file_out]");

  #unlink $file_out;


};
if ($@){
  carp($@);
}


