use Test2::V0;

use Image::PHash;


subtest "pHash6" => sub {
    my $iph = Image::PHash->new('images/M31.jpg');
    my $p1  = $iph->pHash6();

    my $iph2 = Image::PHash->new('images/M31_s.jpg');
    my $p2   = $iph2->pHash6();
    ok(Image::PHash::diff($p1, $p2) < 3, 'Similar images');

    my $iph3 = Image::PHash->new('images/SolarEclipse.jpg');
    my $p3   = $iph3->pHash7();
    ok(Image::PHash::diff($p1, $p3) > 5, 'Dissimilar images');

};

subtest "pHash7" => sub {
    my $iph = Image::PHash->new('images/M31.jpg');
    my $p1  = $iph->pHash7();

    my $iph2 = Image::PHash->new('images/M31_s.jpg');
    my $p2   = $iph2->pHash7();
    ok(Image::PHash::diff($p1, $p2) < 4, 'Similar images');

    my $iph3 = Image::PHash->new('images/SolarEclipse.jpg');
    my $p3   = $iph3->pHash7();
    ok(Image::PHash::diff($p1, $p3) > 6, 'Dissimilar images');
};

done_testing;
