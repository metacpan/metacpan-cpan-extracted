#!/usr/bin/perl

# PRAGMAS
use strict;
use warnings;

# INCLUDES
use Carp;
use Test::More tests => 11;
use Test::Exception;
use FASTAid;

# 1) index an empty file
is( FASTAid::create_index('t/FASTAid_test1.fa'), 0, 'tried to index an empty file' );

# 2) index just a header line
is( FASTAid::create_index('t/FASTAid_test2.fa'), 1, 'index just a header' );

# 3) retrieve just a header line
my $seq2_ref = FASTAid::retrieve_entry('t/FASTAid_test2.fa', 'test_seq3');
is( $seq2_ref->[0], '>test_seq3', 'retrieve just a header' );

# 4) index a single sequence
is( FASTAid::create_index('t/FASTAid_test4.fa'), 1, 'index a single sequence' );

# 5) retrieve a single sequence
my $expected4 = '>test_seq5
AGTCTCGATCGATCGACTAGCTACGATCGACTAGTCGACTACCGACTCAGCATACAGCCA
TACTACTCAGCATCACTATGCATGACTACGATCACGATCACTACTTTGGGCTATCATCGC
GACTAGCGCTACGACGACTCGCCGAATCATCGCGACTATACGCAGCTAGCAGACTCAGAC';

my $seq4_ref = FASTAid::retrieve_entry('t/FASTAid_test4.fa', 'test_seq5');
is( $seq4_ref->[0], $expected4, 'retrieve a single sequence' );

# 6) call retrieve_entry without any IDs
throws_ok{ FASTAid::retrieve_entry('t/FASTAid_test4.fa') } qr/Must supply at least one ID/,
	'try to retrieve without an ID';

# 7) index multiple sequences
is( FASTAid::create_index('t/FASTAid_test7.fa'), 1, 'index multiple sequences' );

# 8, 9, 10) retrieve multiple sequences
my @expected8 = (">test_seq8\nAGTCTCGATCGATCGACTAGCTACGATCGACTAGTCGACTACCGACTCAGCATACAGCCA\nTACTACTCAGCATCACTATGCATGACTACGATCACGATCACTACTTTGGGCTATCATCGC\nGACTAGCGCTACGACGACTCGCCGAATCATCGCGACTATACGCAGCTAGCAGACTCAGAC\n",
">test_seq9\nGACTAGCGCTACGACGACTCGCCGAATCATCGCGACTATACGCAGCTAGCAGACTCAGAC\nAGTCTCGATCGATCGACTAGCTACGATCGACTAGTCGACTACCGACTCAGCATACAGCCA\nTACTACTCAGCATCACTATGCATGACTACGATCACGATCACTACTTTGGGCTATCATCGC\n",
">test_seq10\nAGTCTCGATCGATCGACTAGCTACGATCGACTAGTCGACTACCGACTCAGCATACAGCCA\nGACTAGCGCTACGACGACTCGCCGAATCATCGCGACTATACGCAGCTAGCAGACTCAGAC\nTACTACTCAGCATCACTATGCATGACTACGATCACGATCACTACTTTGGGCTATCATCGC\n", );

my @test8_seqs = qw( test_seq8 test_seq9 test_seq10 );
my $seq8_ref = FASTAid::retrieve_entry('t/FASTAid_test7.fa', @test8_seqs );

is( $seq8_ref->[0], $expected8[0], 'retrieve multiple seqs part 1' );
is( $seq8_ref->[1], $expected8[1], 'retrieve multiple seqs part 2' );
is( $seq8_ref->[2], $expected8[2], 'retrieve multiple seqs part 3' );

#11 croak on duplicate sequence ids
throws_ok { FASTAid::create_index('t/FASTAid_test8.fa') } qr/There is already an entry ID/,
	'on duplicated sequence IDs';



# cleanup
unlink <t/*.fec> or croak "could not clean up .fec files: $!\n";

# END
