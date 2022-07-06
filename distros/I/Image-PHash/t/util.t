use Test2::V0;

use Image::PHash;

my $iph = Image::PHash->new('images/M31.jpg');

subtest "reducedimage" => sub {
    my $reduced = $iph->reducedimage();
    isnt($reduced, $iph->{im}, 'Rescaled');
    $iph = Image::PHash->new('images/M31_th.jpg');
    $reduced = $iph->reducedimage();
    is($reduced, $iph->{im}, 'Non rescaled');
};

subtest "dctdump" => sub {
    my $dump = $iph->dctdump();
    is(scalar @$dump, 32*32, '32x32 DCT');
};

subtest "printbitmatrix" => sub {
    my $bits = $iph->printbitmatrix(geometry=>'4x4', reduce=>1);
    is($bits, " 101\n101 \n01  \n1   \n", 'Reduced bits');
    $bits = $iph->printbitmatrix(geometry=>'8');
    is($bits, " 101\n101\n01\n", 'Geometry 8 bits');
    $bits = $iph->printbitmatrix(geometry=>'8',separator=>'|',filler=>'x');
    is($bits, "x|1|0|1|\n1|0|1|\n0|1|\n", 'Geometry 8 bits');
};

subtest "diff" => sub {
    is(Image::PHash::diff('A','B'), 1, '4 bit diff');
    is(Image::PHash::diff('AAAAAAAAAAAAAAAAA','AAAAAAAAAAAAAAAAB'), 1, '>64 bit diff');
};

done_testing;