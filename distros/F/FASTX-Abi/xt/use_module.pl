#!/usr/bin/env perl

# ABSTRACT - A script to test some functionalities of FASTX::Abi

use 5.018;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use FASTX::Abi;
use Data::Dumper;
use Term::ANSIColor;
my $test_het = "$Bin/../data/hetero.ab1";
my $test_omo = "$Bin/../data/mt.ab1";


# Import a "heterozigous" chromatogram
my $fastq_h = FASTX::Abi->new({
  filename  => "$test_het",
  trim_ends => 1,
});

# Import a standard (non hetero) chromatogram
my $fastq_o = FASTX::Abi->new({
  filename  => "$test_omo",
  trim_ends => 1,
});

# Print properties and FASTQ for both objects
for my $trace_object ($fastq_h, $fastq_o) {
  say color('bold'), "Name   :\t",   $trace_object->{sequence_name} , color('reset'), " [", $trace_object->{filename} , "]";
  say "Iso_seq:\t",$trace_object->{iso_seq};
  say "Diffs  :\t",  $trace_object->{diff}, "\t", join(', ', @{ $trace_object->{diff_array}});
  my $info = $trace_object->get_trace_info();
  print color('blue'), Dumper $info;
  say color('yellow'),substr($trace_object->get_fastq(), 0, 44), color('reset'),'...';
}

say color('bold'),  "NOW TESTING ERROR", color('reset');
my $test_abi;
my $eval = eval {
 $test_abi = FASTX::Abi->new({   filename  => "$test_het",   asdbad_attribute => 1});
 1;
};
if (defined $eval) {
  die "Error: passing wrong attribute should confess\n";
} else {
  say color('green'), 'ok: ', color('reset'), "Failed loading bad attribute";
}
