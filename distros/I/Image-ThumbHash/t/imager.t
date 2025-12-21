use Test2::V0;
use Image::ThumbHash qw(
    imager_to_thumb_hash
);
use FindBin qw($Bin);
use MIME::Base64 qw(encode_base64);

eval { require Imager }
    or skip_all $@;

my %supported_formats = map +($_ => 1), Imager->read_types;

for my $known (
    ['sunrise.jpeg',    '1QcSHQRnh493V4dIh4eXh1h4kJUI'],
    ['firefox.png',     'YJqGPQw7sFlslqhFafSE+Q6oJ1h2iHB2Rw'],
    ['somesulmic.jpeg', 'nNcRFYJbl3aPhneKiId3d/hGID8V'],
    ['tolstoy.png',     '24qCFJIrGHafeIAsiFAnmGC7kFJ5OZppBA'],
) {
    my ($file, $expected_hash) = @$known;
    my ($type) = $file =~ /\.([^.]+)\z/
        or die "Can't extract file extension: $file";

    SKIP: {
        $supported_formats{$type}
            or skip "Installed version of Imager does not support reading '$type' files", 1;

        my $img = Imager->new;
        if (!$img->read(file => "$Bin/data/$file")) {
            my $error = $img->errstr;
            die $error;
        }

        my $hash = imager_to_thumb_hash $img;
        (my $hash_b64 = encode_base64 $hash, '') =~ s/=+\z//;  # strip padding
        is $hash_b64, $expected_hash, "data/$file has expected thumb hash";
    }
}

done_testing;
