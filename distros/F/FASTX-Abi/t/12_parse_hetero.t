use strict;
use warnings;
use FindBin qw($Bin);
use Test::More;

use_ok 'FASTX::Abi';

# THIS TEST USES A HETERO CHROMATOGRAM (contains ambiguous bases)
my $chromatogram = "$Bin/../data/hetero.ab1";

if (-e "$chromatogram") {
    my $data = FASTX::Abi->new({ filename => "$chromatogram" });
    ok(length($data->{raw_sequence}) == length($data->{raw_quality}), "raw quality and rawr sequence length matches" );
    ok(length($data->{sequence}) == length($data->{quality}), "quality and sequence length matches" );
    ok(length($data->{raw_sequence}) >= length($data->{seq1}), "Raw sequence length >= filtered sequence length" );

    ok( $data->{seq1} ne $data->{seq2} , "Hetero sequences are called and different" );
    my $differences = $#{ $data->{diff_array} } + 1;
    ok( $data->{diff} > 0, "ambiguity detected in at hetero.ab1");
    ok( ${ $data->{diff_array} }[0] > 0, "ambiguity position #1 reported" );
    ok( ${ $data->{diff_array} }[1] > 0, "ambiguity position #2 reported" );
    ok( $differences == $data->{diff}, "Array of different positions matches number of differences: $differences ");
    ok( $data->{iso_seq} eq 0, "{iso_seq} property correct = 0");
  }

  # THIS TEST USES A NON HETERO CHROMATOGRAM
  $chromatogram = "$Bin/../data/mt.ab1";

  if (-e "$chromatogram") {
      my $data = FASTX::Abi->new({ filename => "$chromatogram" });

      ok( $data->{seq1} eq $data->{seq2} , "Hetero sequences are called and NOT different" );

      ok( $data->{diff} == 0, "ambiguity NOT detected in at mt.ab1 (diff=0)");
      ok( ! defined ${ $data->{diff_array} }[0], "ambiguity _position_ NOT detected in at mt.ab1 (diff_array empty)");
      ok( $data->{iso_seq} eq 1, "{iso_seq} property correct = 1");
    }




done_testing();
