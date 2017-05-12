#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok( 'MARC::File::MiJ' ) || print "Bail out!\n";
    use_ok( 'MARC::Record::MiJ' ) || print "Bail out!\n";
}

diag( "Testing MARC::File::MiJ $MARC::File::MiJ::VERSION, Perl $], $^X" );

use MARC::Record;
use MARC::Batch;
use File::Spec;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $filename = File::Spec->catfile( 't', 'camel.usmarc' );
my $batch = new MARC::Batch( 'USMARC', $filename );
my $r = $batch->next;

my $mij_structure = MARC::Record::MiJ->to_mij_structure($r);
my $mij_string = Dumper($mij_structure);

# Now make a new one and compare

my $r2 = MARC::Record::MiJ->new_from_mij_structure($mij_structure);
my $mij_structure2 = MARC::Record::MiJ->to_mij_structure($r2);
my $mij_string2 = Dumper($mij_structure2);

is_deeply($r, $r2, "Records are identical");
is_deeply($mij_structure, $mij_structure2, "Intermediate structure is identical");
is($mij_string, $mij_string2, "Dumper output is identical");


# Test monkey patching
is_deeply($r->to_mij_structure, $r2->to_mij_structure, "Monkey patch \$r->to_mij_structure");
is_deeply(MARC::Record->new_from_mij_structure($mij_structure), MARC::Record->new_from_mij_structure($mij_structure2), "Monkey patch MARC::Record->new_from_mij_structure");
is_deeply($r, MARC::Record->new_from_mij($r->to_mij), "Round trip via MARC::Record monkey patches");



# memoized json thing working?

my $json1 = MARC::Record::MiJ->json;
my $json2 = MARC::Record::MiJ->json;
is($json1, $json2, 'Memoized json object working');


# Read in a file produced by ruby-marc
# File has nine records


my $binfile = File::Spec->catfile( 't', 'test.mrc' );
my $jsonfile = File::Spec->catfile( 't', 'test.ndj' );

my @binrecords;
my @rubyjsonrecords;

$batch = new MARC::Batch('USMARC', $binfile);
while (my $r = $batch->next) {
  push @binrecords, $r;
}


$batch = new MARC::Batch('MiJ', $jsonfile);
while (my $r = $batch->next) {
  push @rubyjsonrecords, $r;
}

foreach my $i (0..8) {
  is($binrecords[$i]->as_formatted, $rubyjsonrecords[$i]->as_formatted, "Record $i matches");
}

# check to make sure we can call #in directly

$r = MARC::File::MiJ->in($jsonfile)->next;
is_deeply($r, $rubyjsonrecords[0], "Both MARC::Batch and MARC::File::MiJ work");


# Check to make sure created records are identical by getting the raw ruby json
# and decoding it to a hashref, and using perl to turn the (already verified 
# to be identical) records into json and then decoding

my @perljsonstructure =  map {$json1->decode(MARC::Record::MiJ->to_mij($_))} @binrecords;
my @rubyjsonstructure;
open(RJ, $jsonfile) or die "Can't re-open jsonfile: $!";
while (<RJ>) {
  push @rubyjsonstructure, $json1->decode($_);
}

foreach my $i (0..8) {
  is_deeply($rubyjsonstructure[$i], $perljsonstructure[$i], "Perl/Ruby identical for record $i");
}

done_testing();
