use Test2::V0;
use Image::ThumbHash qw(
    rgba_to_thumb_hash
);
use FindBin qw($Bin);
use Imager ();
use MIME::Base64 qw(encode_base64);

for my $known (
    ['sunrise.jpg', '1QcSHQRnh493V4dIh4eXh1h4kJUI'],
    ['firefox.png', 'YJqGPQw7sFlslqhFafSE+Q6oJ1h2iHB2Rw'],
) {
    my ($file, $expected_hash) = @$known;

    SKIP: {
        my $img = Imager->new;
        if (!$img->read(file => "$Bin/data/$file")) {
            my $error = $img->errstr;
            if ($error =~ /^format 'png' not supported/ && $ENV{GITHUB_ACTIONS}) {
                skip "github is being stupid: Imager can't read PNG files: $error";
            }
            die $error;
        }
        $img = $img->convert(preset => 'addalpha');
        $img->write(type => 'raw', data => \my $data) or die $img->errstr;

        my $hash = rgba_to_thumb_hash $img->getwidth, $img->getheight, $data;
        (my $hash_b64 = encode_base64 $hash, '') =~ s/=+\z//;  # strip padding
        is $hash_b64, $expected_hash, "data/$file has expected thumb hash";
    }
}

done_testing;
