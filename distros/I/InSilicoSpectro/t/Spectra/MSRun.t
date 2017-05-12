#!/usr/bin/env perl
use strict;
use Test::More tests => 4;
use File::Basename;
my $dir=dirname $0;

chdir $dir;

my $msms_regexp = 'Spot_Id: (\d+), Peak_List_Id';
my $pmf_regexp = 'Spot Id: (\d+), Peak List Id';
my $msmsKey = 'sample_0%cmpd_32';
my $theoPmfKey = 'pmf_31';
my $mapping_file = 'mapping_test.txt';
my $idjFile = './idj_pmf+msms_unmapped.xml';

use InSilicoSpectro::Spectra::MSRun;

my $msRun= InSilicoSpectro::Spectra::MSRun->new();
ok(ref($msRun) eq 'InSilicoSpectro::Spectra::MSRun', 'object construction');

$msRun->readIDJ($idjFile);

ok($msRun->getNbSpectra == 43, 'spectra number');

$msRun->msms2pmfKeyBuildRelation( title_msmsregexp => $msms_regexp,
																	title_pmfregexp => $pmf_regexp );

while(my($key, $value) = each %{ $msRun->msms2pmfRelation })
 	{ print "$key\t$value\n"; }

ok($msRun->msms2pmfRelation($msmsKey) eq $theoPmfKey, 'build relation with regexps');

$msRun->clear_msms2pmfRelation();

$msRun->msms2pmfKeyBuildRelation( textfile => $mapping_file );
ok($msRun->msms2pmfRelation($msmsKey) eq $theoPmfKey, 'build relation with file');



