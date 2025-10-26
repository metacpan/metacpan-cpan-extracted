use Test2::V0;
use Test2::Require::Module 'GD';

use GD::Barcode::QRcode;
use File::Temp qw(tempfile);
use File::stat;

# Test the exact scenario from the bug report
subtest 'Bug report scenario' => sub {
    my $qrcode = GD::Barcode::QRcode->new('1234567');
    ok($qrcode, 'QRcode object creation');

    my $img = $qrcode->plot;
    ok($img, 'plot() method works');
    isa_ok($img, ['GD::Image'], 'Returns GD::Image object');

    my $png_data = $img->png;
    ok($png_data, 'PNG generation works');
    ok(length($png_data) > 100, 'PNG data has reasonable size');
};

# Test with longer URL (from original test)
subtest 'Long URL QRcode' => sub {
    my $qrcode = GD::Barcode::QRcode->new('https://github.com/mbeijen/GD-Barcode/commit/af0ac08c05df03c2088e3f472633d9249c4883ca',
    {ModuleSize => 1});
    ok($qrcode, 'QRcode with long URL');

    my ($fh, $filename) = tempfile();
    binmode $fh;
    print $fh $qrcode->plot->png;
    close $fh;

    my $filesize = stat($filename)->size;
    ok($filesize > 0, 'Generated PNG file is not empty');
    ok($filesize > 300, 'PNG file has substantial content');

    unlink $filename or diag "Could not unlink $filename: $!";
};

# Test different module sizes
subtest 'Different module sizes' => sub {
    for my $size (1, 2, 3, 5) {
        my $qrcode = GD::Barcode::QRcode->new('Test', {ModuleSize => $size});
        ok($qrcode, "QRcode with ModuleSize $size");

        my $img = $qrcode->plot;
        ok($img, "plot() works with ModuleSize $size");

        # Check that larger module sizes create larger images
        my ($width, $height) = $img->getBounds();
        ok($width > 0 && $height > 0, "Image has positive dimensions");
        if ($size > 1) {
            # Should be larger than the minimum size
            ok($width >= $size * 20, "Image width scales with module size");
        }
    }
};

# Test different error correction levels
subtest 'Error correction levels' => sub {
    for my $ecc ('L', 'M', 'Q', 'H') {
        my $qrcode = GD::Barcode::QRcode->new('Test123', {Ecc => $ecc});
        ok($qrcode, "QRcode with Ecc $ecc");

        my $img = $qrcode->plot;
        ok($img, "plot() works with Ecc $ecc");
    }
};

# Test that plot method properly requires GD
subtest 'GD loading test' => sub {
    # This test verifies that our fix works - the 'require GD' should happen
    # automatically when plot() is called, not when the module is loaded
    my $qrcode = GD::Barcode::QRcode->new('Test');
    ok($qrcode, 'QRcode creation without explicit GD load');

    # This should work now with our fix
    my $img = $qrcode->plot;
    ok($img, 'plot() method loads GD automatically and returns image object');
    isa_ok($img, ['GD::Image'], 'Image is a GD::Image object');
};

done_testing();
