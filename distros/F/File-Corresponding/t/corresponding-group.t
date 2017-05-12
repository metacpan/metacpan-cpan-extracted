
use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;

use lib "lib";


use_ok("File::Corresponding::File::Profile");
use_ok("File::Corresponding::Group");



ok(
    File::Corresponding::Group->new({
    }),
    "Create new profile w/ only defaults ok",
);



ok(
    File::Corresponding::Group->new({
        name => "ABC files",
        file_profiles => [
            File::Corresponding::File::Profile->new({
                name => "Lower abc",
                regex => qr|abc/(\w+)$|,
                sprintf => "abc/%s"
            }),
            File::Corresponding::File::Profile->new({
                name => "Upper abc",
                regex => qr|ABC/(\w+)$|,
                sprintf => "ABC/%s"
            }),
        ]
    }),
    "Create new profile w/ only defaults ok",
);




__END__
