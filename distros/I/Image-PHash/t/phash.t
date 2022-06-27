use Test2::V0;

use Image::PHash;

my %libs = (
    'Image::Imlib2' => {resize        => 64},
    GD              => {resize        => 48},
    'Image::Magick' => {magick_filter => 'Triangle'},
    Imager          => {qtype         => 'normal'}
);

my $cnt = 0;
foreach my $lib (keys %libs) {
    next unless eval "require $lib;";
    next if $lib eq 'Imager' && !eval "require Imager::File::JPEG;";
    $cnt++;

    foreach my $method (qw/average median average_x log diff/) {
        my %settings = (geometry => 64, method => $method);
        subtest "Testing $lib with $method" => sub {

            my $iph = Image::PHash->new('images/M31.jpg', $lib);
            my @arr = $iph->pHash(%settings);
            is(join('', @arr), match(qr/^[01]{64}$/), 'array context');
            my $p1  = $iph->pHash(%settings);
            my $pm  = $iph->pHash(%settings, mirror=>1);
            my $pmp = $iph->pHash(%settings, mirrorproof=>1);
            hash_check($p1);

            my $iph2 = Image::PHash->new('images/M31_s.jpg', $lib);
            my $p2   = $iph2->pHash(%settings);
            hash_check($p2);
            ok(Image::PHash::diff($p1, $p2) < 8, 'Similar images');

            my $iph3 = Image::PHash->new('images/SolarEclipse.jpg', $lib);
            my $p3   = $iph3->pHash(%settings);
            hash_check($p3);
            ok(Image::PHash::diff($p1, $p3) > 16, 'Dissimilar images');

            my $iph4 = Image::PHash->new('images/M31_mirr.jpg', $lib);
            my $p4 = $iph4->pHash(%settings);
            ok(Image::PHash::diff($pm, $p4) < 4, 'Similar images (mirror)');
            my $p4mp = $iph4->pHash(%settings, mirrorproof=>1);
            ok(Image::PHash::diff($pmp, $p4mp) < 4, 'Similar images (mirrorproof)');
        };
        subtest "Testing $lib with extra settings" => sub {
            my $iph = Image::PHash->new('images/M31.jpg', $lib, $libs{$lib});
            my $p   = $iph->pHash();
            hash_check($p)
        };
    }
    subtest "Testing $lib with 32x32 img" => sub {
        my $iph = Image::PHash->new('images/M31_th.jpg', $lib);
        my $p   = $iph->pHash();
        is($p, 'D39F36E74DFB6D9F', 'Same hash expected for fixed image');
    };
}

# ok($cnt > 0, "At least 1 image library required - $cnt successfully loaded");

sub hash_check {
    my $hash = shift;
    my $len  = shift || 64;
    is(length($hash), $len / 4, 'Hash length OK');
    is($hash, match(qr/^[A-F0-9]+$/), 'Hex OK');
    ok($hash =~ tr/0// < 6 && ($hash =~ tr/F//) < 6, 'Not low entropy');
}

done_testing;
