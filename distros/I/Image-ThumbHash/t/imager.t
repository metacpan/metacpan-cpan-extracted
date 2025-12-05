use Test2::V0;
use Image::ThumbHash qw(
    imager_to_thumb_hash
);
use FindBin qw($Bin);
use MIME::Base64 qw(encode_base64);

eval { require Imager }
    or skip_all $@;

for my $known (
    ['sunrise.jpg',    '1QcSHQRnh493V4dIh4eXh1h4kJUI'],
    ['firefox.png',    'YJqGPQw7sFlslqhFafSE+Q6oJ1h2iHB2Rw'],
    ['somesulmic.jpg', 'nNcRFYJbl3aPhneKiId3d/hGID8V'],
    ['tolstoy.png',    '24qCFJIrGHafeIAsiFAnmGC7kFJ5OZppBA'],
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

        my $hash = imager_to_thumb_hash $img;
        (my $hash_b64 = encode_base64 $hash, '') =~ s/=+\z//;  # strip padding
        is $hash_b64, $expected_hash, "data/$file has expected thumb hash";
    }
}

done_testing;
