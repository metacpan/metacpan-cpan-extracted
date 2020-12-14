# This tests setting text in a PNG image.

use warnings;
use strict;
use Test::More;
use FindBin '$Bin';
use Image::PNG::Const ':all';
use Image::PNG::Libpng ':all';
BEGIN: {
    use lib "$Bin";
    use IPNGLT;
};

skip_itxt ();
skip_old ();

my $file = "$Bin/set-text.png";
if (-f $file) {
    unlink $file;
}
my $png = create_write_struct ();
$png->set_verbosity (1);
$png->set_IHDR ({width => 1, height => 1, bit_depth => 8, color_type => PNG_COLOR_TYPE_GRAY});
$png->set_rows (['X']);
my $text = [
	{key => 'baba', text => 'bubu'},
	{key => 'bobo', text => 'bibi',
	 compression => PNG_TEXT_COMPRESSION_zTXt},
	{key => 'bingbing', },
    ];
$png->set_text ($text);
$png->write_png_file ($file);
my $check = read_png_file ($file);
my $check_text = $check->get_text ();
# We can't use is_deeply because we get PNG junk in the returned hash
# like "compression", "text_length", etc.
for my $i (0..$#$text) {
    my $x = $text->[$i];
    my $y = $check_text->[$i];
    for my $k (keys %$x) {
	ok (defined $y->{$k}, "Got key $k back for text chunk $i");
	is ($y->{$k}, $x->{$k}, "Value for $k is the same for text chunk $i");
    }
}
if (-f $file) {
    unlink $file;
}

# Test error cases

eval {
    my $badpng = create_write_struct ();
    $badpng->set_text ([{'nokey' => 'here'}]);
};
ok ($@, "Got error adding text chunk without 'key'");

eval {
    my $badpng = create_write_struct ();
    $badpng->set_text (['not a hash']);
};
ok ($@, "Got error adding text chunk which is not a hash");

eval {
    my $badpng = create_write_struct ();
    my $badkey = 'x' x 80;
    $badpng->set_text ([{key => $badkey}]);
};
ok ($@, "Got error with too-long key");
like ($@, qr!80!, "Got length of key");

eval {
    my $badpng = create_write_struct ();
    my $badkey = '';
    $badpng->set_text ([{key => $badkey}]);
};
ok ($@, "Got error with too-short key");
like ($@, qr!empty!, "Got empty key");

done_testing ();
exit;
