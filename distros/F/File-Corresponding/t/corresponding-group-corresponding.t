
use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;
use Test::Differences;

use File::chdir;
use File::Basename;
use Path::Class qw/ dir file /;


use lib "lib";

use File::Corresponding::Group;
use File::Corresponding::File::Profile;
use File::Corresponding::File::Found;





{
    local $CWD = dir( dirname(__FILE__), "data" );



    diag("No profiles");


    ok(
        my $group = File::Corresponding::Group->new({
            name => "ABC files",
        }),
        "Create new empty group",
    );
    is_deeply(
        $group->corresponding("bogus file"),
        [],
        "->corresponding with no profiles returns empty arrayref",
    );



    diag("Setup a config to match things under data/corresponding");
    ok(
        $group = File::Corresponding::Group->new({
            name => "Number files",
            file_profiles => [
                my $profile_abc = File::Corresponding::File::Profile->new({
                    name    => "abc",
                    regex   => qr|abc/([\w.]+)$|,
                    sprintf => "abc/%s"
                }),
                my $profile_def = File::Corresponding::File::Profile->new({
                    name    => "def",
                    regex   => qr|elsewhere/def/([\w.]+)$|,
                    sprintf => "elsewhere/def/%s"
                }),
                my $profile_ghi = File::Corresponding::File::Profile->new({
                    name    => "ghi",
                    regex   => qr|ghi/([\w.]+)$|,
                    sprintf => "ghi/%s"
                }),
            ]
        }),
        "Create new group ok",
    );


    diag("Try to find matching profiles");
    is_deeply(
        [ $group->matching_file_fragment_profile("bogus file") ],
        [],
        "Matching against bogus file returns nothing",
    );

    is_deeply(
        [ $group->matching_file_fragment_profile("corresponding/abc/test.txt") ],
        [ "corresponding/", "test.txt", $profile_abc ],
        "Matching against matching file returns fragment and profile",
    );



    diag("Find corresponding");
    eq_or_diff(
        $group->corresponding("corresponding/abc/test.txt"),
        [ ],
        "  missing file, nothing",
    );

    eq_or_diff(
        $group->corresponding("corresponding/abc/1.txt"),
        [
            my $found_1_def = File::Corresponding::File::Found->new({
                file             => "corresponding/elsewhere/def/1.txt",
                found_profile    => $profile_def,
                matching_profile => $profile_abc,
            }),
        ],
        "  testing 1.txt, finds one present",
    );

    eq_or_diff(
        $group->corresponding("corresponding/abc/2.txt"),
        [
            my $found_2_def = File::Corresponding::File::Found->new({
                file             => "corresponding/elsewhere/def/2.txt",
                found_profile    => $profile_def,
                matching_profile => $profile_abc,
            }),
            my $found_2_ghi = File::Corresponding::File::Found->new({
                file             => "corresponding/ghi/2.txt",
                found_profile    => $profile_ghi,
                matching_profile => $profile_abc,
            }),
        ],
        "  testing 2.txt, finds two present",
    );



}

__END__
