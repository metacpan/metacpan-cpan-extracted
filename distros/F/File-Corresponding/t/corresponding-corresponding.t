
use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;
use Test::Differences;

use File::chdir;
use File::Basename;
use Path::Class qw/ dir file /;


use lib "lib";

use File::Corresponding;
use File::Corresponding::Group;
use File::Corresponding::File::Profile;
use File::Corresponding::File::Found;




{
    local $CWD = dir( dirname(__FILE__), "data" );


    diag("Setup a config to match things under data/corresponding");
    ok(
        my $group_a = File::Corresponding::Group->new({
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
            ],
        }),
        "Create new group ok",
    );

    ok(
        my $group_b = File::Corresponding::Group->new({
            name => "Number files",
            file_profiles => [
                $profile_ghi,
                my $profile_jkl = File::Corresponding::File::Profile->new({
                    name    => "jkl",
                    regex   => qr|jkl/([\w.]+)$|,
                    sprintf => "jkl/%s"
                }),
            ],
        }),
        "Create new group ok",
    );



    my $corresponding_alpha = File::Corresponding->new({
        name           => "alpha",
        profile_groups => [ $group_a ],
    });

    eq_or_diff(
        $corresponding_alpha->corresponding("corresponding/abc/2.txt"),
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
        "  testing 2.txt, finds two present in one group",
    );



    my $corresponding_beta = File::Corresponding->new({
        name           => "beta",
        profile_groups => [ $group_a, $group_b ],
    });

    eq_or_diff(
        $corresponding_beta->corresponding("corresponding/abc/2.txt"),
        [ $found_2_def, $found_2_ghi ],
        "  testing 2.txt, finds two present in two group (only found it in one)",
    );

    eq_or_diff(
        $corresponding_beta->corresponding("corresponding/ghi/2.txt"),
        [
            my $found_2_abc = File::Corresponding::File::Found->new({
                file             => "corresponding/abc/2.txt",
                matching_profile => $profile_ghi,
                found_profile    => $profile_abc,
            }),
            my $found_ghi2_def = File::Corresponding::File::Found->new({
                file             => "corresponding/elsewhere/def/2.txt",
                matching_profile => $profile_ghi,
                found_profile    => $profile_def,
            }),

            my $found_2_jkl = File::Corresponding::File::Found->new({
                file             => "corresponding/jkl/2.txt",
                matching_profile => $profile_ghi,
                found_profile    => $profile_jkl,
            }),
        ],
        "  testing 2.txt, finds three present in two group (found it in both)",
    );
}



__END__
