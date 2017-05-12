
use strict;
use warnings;
use Test::More tests => 10;
use Test::Exception;

use File::chdir;
use File::Basename;
use Path::Class qw/ dir file /;

use lib "lib";



use_ok("File::Corresponding::File::Profile");
use_ok("File::Corresponding::File::Found");

dies_ok(
    sub { File::Corresponding::File::Profile->new({}) },
    "Create new profile w/o regex default ok",
);


ok(
    File::Corresponding::File::Profile->new({
        regex => qr/abc/,
    }),
    "Create new profile w/ regex default ok",
);



ok(
    my $profile = File::Corresponding::File::Profile->new({
        name    => "Test",
        sprintf => "abc/%s",
        regex   => qr|abc/(\w+)$|,
    }),
    "Create new profile w/ all values ok",
);



diag("matching_file_fragment");
is_deeply(
    [ $profile->matching_file_fragment("bogus_file") ],
    [],
    "Nonmatching file matches nothing",
);

is_deeply(
    [ $profile->matching_file_fragment("/some/project/abc/a") ],
    ["/some/project/", "a"],
    "Matching file works",
);




diag("new_found_if_file_exists");
{
    local $CWD = dir( dirname(__FILE__), "data" );


    my $profile_abc = File::Corresponding::File::Profile->new({
        name => "abc",
        regex => qr|abc/([\w.]+)$|,
        sprintf => "abc/%s"
    });
    my $profile_def = File::Corresponding::File::Profile->new({
        name => "def",
        regex => qr|elsewhere/def/([\w.]+)$|,
        sprintf => "elsewhere/def/%s"
    });


    is_deeply(
        [ $profile_abc->new_found_if_file_exists($profile_def, "corresponding", "bogus_file") ],
        [],
        "Nonmatching file returns nothing",
    );

    is_deeply(
        [ $profile_abc->new_found_if_file_exists($profile_def, "corresponding", "2.txt") ],
        [
            my $found_abc = File::Corresponding::File::Found->new({
                file             => "corresponding/abc/2.txt",
                found_profile    => $profile_abc,
                matching_profile => $profile_def,
            }),
        ],
        "Found file returns proper found object",
    );


    my $profile_abc_missing_sprintf = File::Corresponding::File::Profile->new({
        name => "abc",
        regex => qr|abc/([\w.]+)$|,
    });
    is_deeply(
        [ $profile_abc_missing_sprintf->new_found_if_file_exists($profile_def, "corresponding", "2.txt") ],
        [ ],
        "Found file but with missing sprintf returns empty",
    );




}


__END__
