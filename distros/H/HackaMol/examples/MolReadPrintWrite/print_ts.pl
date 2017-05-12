#!/usr/bin/env perl
use Modern::Perl;
use HackaMol;

my $hack = HackaMol->new( name => "hackitup" );
my $mol  = $hack->read_file_mol("1L2Y.pdb"); #download from pdb.org
$mol->print_pdb_ts([3 .. 15],'print_ts_test.pdb');

