use 5.012;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use Data::Dumper;
use_ok 'FASTX::Abi';


my $rawfor = FASTX::Abi->new({
    filename => "$RealBin/../data/A_forward.ab1"

});
my $rawrev = FASTX::Abi->new({
    filename => "$RealBin/../data/A_reverse.ab1"
});
my $for = FASTX::Abi->new({
    filename => "$RealBin/../data/A_forward.ab1",
    trim_ends => 1,
    min_qual  => 44,
    bad_bases => 3,
    wnd       => 5,
});
my $rev = FASTX::Abi->new({
    filename => "$RealBin/../data/A_reverse.ab1",
    trim_ends => 1,
    min_qual  => 44,
    bad_bases => 3,
    wnd       => 5,
});

ok(length($rawfor->{seq1}) > length($for->{seq1}), 
    "Trimmed forward sequence is shorter " . 
        length($rawfor->{seq1}) .
        " >  " . length($for->{seq1})
    );
my $consensus = $for->merge($rev);

say $consensus;

ok(length($consensus) > length($for->{seq1}), 'Merged sequence longer than FOR');
done_testing();
