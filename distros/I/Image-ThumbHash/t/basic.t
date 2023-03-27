use Test2::V0;
use Image::ThumbHash qw(
    rgba_to_png
    rgba_to_data_url
    thumb_hash_to_rgba
    thumb_hash_to_average_rgba
    thumb_hash_to_approximate_aspect_ratio
    thumb_hash_to_data_url
);
use MIME::Base64 qw(decode_base64);
use FindBin qw($Bin);

like
    dies { () = thumb_hash_to_rgba 'abcd' },
    qr/\bthumb_hash_to_rgba: thumb hash length is less than 5\b/,
    "thumb_hash_to_rgba throws if argument too short";
like
    dies { my $dummy = thumb_hash_to_rgba 'abcdefg' },
    qr/\bthumb_hash_to_rgba: must be called in list context\b/,
    "thumb_hash_to_rgba dies in scalar context";

like
    dies { () = thumb_hash_to_average_rgba 'abcd' },
    qr/\bthumb_hash_to_average_rgba: thumb hash length is less than 5\b/,
    "thumb_hash_to_average_rgba throws if argument too short";
like
    dies { my $dummy = thumb_hash_to_average_rgba 'abcdefg' },
    qr/\bthumb_hash_to_average_rgba: must be called in list context\b/,
    "thumb_hash_to_average_rgba dies in scalar context";

{
    my $list = "$Bin/data/pngified.txt";
    open my $fh, '<', $list
        or die "Can't open $list: $!";
    while (my $spec = readline $fh) {
        my ($thumbhash_b64, $xratio, $xr, $xg, $xb, $xa, $expected_png_b64) = split ' ', $spec;
        my $hash = decode_base64 $thumbhash_b64;
        my $expected_png = decode_base64 $expected_png_b64;
        my $expected_url = "data:image/png;base64,$expected_png_b64";

        my @average_color = thumb_hash_to_average_rgba $hash;
        is [map sprintf('%.6f',$_), @average_color], [$xr, $xg, $xb, $xa];

        my $approx_aspect_ratio = thumb_hash_to_approximate_aspect_ratio $hash;
        is $approx_aspect_ratio, $xratio;

        my ($width, $height, $rgba) = thumb_hash_to_rgba $hash;

        my $png = rgba_to_png $width, $height, $rgba;
        is $png, $expected_png;

        my $url = rgba_to_data_url $width, $height, $rgba;
        is $url, $expected_url;

        my $url2 = thumb_hash_to_data_url $hash;
        is $url2, $expected_url;
    }
}

done_testing;
