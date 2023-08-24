use Test2::V0;
use POSIX qw/ceil/;

use Image::PHash;

my %libs = (
    'Image::Imlib2' => {resize        => 64},
    GD              => {resize        => 48},
    'Image::Magick' => {magick_filter => 'Triangle'},
    Imager          => {imager_qtype  => 'normal'}
);

my $cnt = 0;
foreach my $lib (keys %libs) {
    next unless eval "require $lib;";
    next if $lib eq 'Imager' && !eval "require Imager::File::JPEG;";
    $cnt++;
    my $iph  = Image::PHash->new('images/M31.jpg',          $lib);
    my $iph2 = Image::PHash->new('images/M31_s.jpg',        $lib);
    my $iph3 = Image::PHash->new('images/SolarEclipse.jpg', $lib);
    my $iph4 = Image::PHash->new('images/M31_mirr.jpg',     $lib);
    my $iphx = Image::PHash->new('images/M31.jpg',          $lib, $libs{$lib});
    my $ipht = Image::PHash->new('images/M31_th.jpg',       $lib);

    foreach my $method (qw/average median average_x log diff/) {
        my %settings = (geometry => 64, method => $method);
        my %set_sq   = (geometry => '8x8', method => $method);
        my %set_red  = (geometry => '8x8', reduce => 1, method => $method);
        subtest "Testing $lib with $method" => sub {
            my @arr = $iph->pHash(%settings);
            is(join('', @arr), match(qr/^[01]{64}$/), 'array context');
            my $p1  = $iph->pHash(%settings);
            my $p1s = $iph->pHash(%set_sq);
            my $p1r = $iph->pHash(%set_red);
            my $pm  = $iph->pHash(%settings, mirror => 1);
            my $pmp = $iph->pHash(%settings, mirrorproof => 1);
            hash_check($p1);
            hash_check($p1s);
            hash_check($p1r, 35);

            my $pmt  = $iph->pHash(%settings, mirror      => 1);
            my $pmpt = $iph->pHash(%settings, mirrorproof => 1);
            is($pm,  $pmt,  'Verify recalculating mirror');
            is($pmp, $pmpt, 'Verify recalculating mirrorproof');

            my $p2  = $iph2->pHash(%settings);
            my $p2s = $iph2->pHash(%set_sq);
            my $p2r = $iph2->pHash(%set_red);
            hash_check($p2);
            hash_check($p2s);
            hash_check($p2r, 35);
            ok(Image::PHash::diff($p1,  $p2) < 8,  'Similar images');
            ok(Image::PHash::diff($p1s, $p2s) < 8, 'Similar images');
            ok(Image::PHash::diff($p1r, $p2r) < 6, 'Similar images');

            my $p3  = $iph3->pHash(%settings);
            my $p3s = $iph3->pHash(%set_sq);
            my $p3r = $iph3->pHash(%set_red);
            hash_check($p3);
            hash_check($p3s);
            hash_check($p3r, 35);
            ok(Image::PHash::diff($p1,  $p3) > 16,  'Dissimilar images');
            ok(Image::PHash::diff($p1s, $p3s) > 16, 'Dissimilar images');
            ok(Image::PHash::diff($p1r, $p3r) > 12, 'Dissimilar images');

            my $p4 = $iph4->pHash(%settings);
            ok(Image::PHash::diff($pm, $p4) < 4, 'Similar images (mirror)');
            my $p4mp = $iph4->pHash(%settings, mirrorproof => 1);
            ok(Image::PHash::diff($pmp, $p4mp) < 4, 'Similar images (mirrorproof)');
        };
        subtest "Testing $lib with extra settings" => sub {
            my $p = $iphx->pHash();
            hash_check($p)
        };
    }

    subtest "Testing $lib with 32x32 img" => sub {
        my $p = $ipht->pHash();
        is($p, 'D39F36E74DFB6D9F', 'Same hash expected for fixed image');
    };

    subtest "Loading $lib object" => sub {
        my $obj;
        if ($lib eq 'Image::Imlib2') {
            $obj = Image::Imlib2->load('images/M31_s.jpg');
        } elsif ($lib eq 'GD') {
            GD::Image->trueColor(1);
            $obj = GD::Image->new('images/M31_s.jpg');
        } elsif ($lib eq 'Image::Magick') {
            $obj = Image::Magick->new();
            $obj->Read('images/M31_s.jpg');
        } else {
            $obj = Imager->new('file' => 'images/M31_s.jpg');
        }
        my $iph = Image::PHash->new($obj);
        is($iph->{im}, $obj, 'object loaded');
    };
}

# ok($cnt > 0, "At least 1 image library required - $cnt successfully loaded");

sub hash_check {
    my $hash = shift;
    my $len  = shift || 64;
    is(length($hash), ceil($len / 4), 'Hash length OK');
    is($hash, match(qr/^[A-F0-9]+$/), 'Hex OK');
    ok(($hash =~ tr/0//) < 6 && ($hash =~ tr/F//) < 6, 'Not low entropy');
}

done_testing;
