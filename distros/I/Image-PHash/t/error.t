use Test2::Tools::Exception qw/dies/;
use Test2::V0;

use Image::PHash;

like(
    dies { Image::PHash->new() },
    qr/file or data expected/,
    "No file/data passed"
);

like(
    dies { Image::PHash->new('test', 1, 1) },
    qr/Hashref expected/,
    "No hashref settings"
);

like(
    dies { Image::PHash->new('test', 1, {resize=>5}) },
    qr/> 5 expected/,
    "Resize <= 5"
);

my $obj = {};
bless $obj, 'Other::Type';
like(
    dies { Image::PHash->new($obj, 'test') },
    qr/Object of unknown type/,
    "Unknown object type"
);

like(
    dies { Image::PHash->new('test', 'test') },
    qr/Unknown image library/,
    "Unknown image library"
);

like(
    dies { Image::PHash->new('test') },
    qr/No file at/,
    "No file"
);

my $iph = Image::PHash->new('images/M31.jpg');

like(
    dies { $iph->pHash(mirror=>1, mirrorproof=>1) },
    qr/exclusive/,
    "Mutually exclusive options"
);

like(
    dies { $iph->pHash(geometry=>'64x64') },
    qr/geometry cannot be greater/,
    "Geometry too large"
);

like(
    dies { $iph->pHash(geometry=>'8x12') },
    qr/geometry expected/,
    "Geometry not square"
);

like(
    dies { $iph->pHash(method=>'mean') },
    qr/Unsupported method/,
    "Unsupported method"
);

like(
    warnings { $iph->pHash(mirror_proof=>1) },
    [qr/mirror_proof/],
    "Unknown option"
);

my $blob = 'xdata'x1000;
foreach my $lib (qw/Image::Magick Imager/) {
    next unless eval "require $lib;";
    like(
        warnings { Image::PHash->new($blob, $lib) },
        [qr/Cannot load data/],
        "Can't load fake data with $lib"
    );
}

done_testing;