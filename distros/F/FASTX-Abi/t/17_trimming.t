use 5.012;
use warnings;
use FindBin qw($Bin);
use Test::More;
use Data::Dumper;
use_ok 'FASTX::Abi';
# Test TRACE object
my $dir = "$Bin/../data/";

for my $file (glob "$dir/*.a*") {
  my $trimmed = FASTX::Abi->new({
      filename => "$file",
      trim_ends => 1,
      min_qual  => 30,
  });

  my $untrimmed = FASTX::Abi->new({
      filename => "$file",
      trim_ends => 0,
  });

    my $default = FASTX::Abi->new({
        filename => "$file",
    });

  ok(length( $trimmed->{sequence} ) < length( $untrimmed->{sequence} ), "Trimmed sequence is shorter than untrimmed" );
  ok(length( $default->{sequence} ) < length( $untrimmed->{sequence} ), "Default Trimmed sequence is shorter than untrimmed" );

}

done_testing();
