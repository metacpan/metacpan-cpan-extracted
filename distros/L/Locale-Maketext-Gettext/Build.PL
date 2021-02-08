#! /usr/bin/perl -w
require 5.008;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $build = Module::Build->new(
    dist_name       => "Locale-Maketext-Gettext",
    dist_version    => "1.32",
    dist_abstract   => "Joins gettext and Maketext frameworks",
    dist_author     => "imacat <imacat\@mail.imacat.idv.tw>",
    license         => "perl",
    sign            => 1,
    
    script_files    => [ "script/maketext" ],
    requires        => {
        "perl"          => "5.8.0",
    },
    add_to_cleanup	=> [ "t/test_native.po", "t/locale/en/LC_MESSAGES/test_native.mo" ],

    meta_merge  => {
        "meta-spec" => { version => 2 },
        resources   => {
            homepage    => "https://metacpan.org/release/Locale-Maketext-Gettext",
            repository  => {
                type    => "git",
                url     => "git://github.com/imacat/Locale-Maketext-Gettext.git",
                web     => "https://github.com/imacat/Locale-Maketext-Gettext",
            },
            bugtracker  => {
                "web"   => "https://github.com/imacat/Locale-Maketext-Gettext/issues"
            }
        },
    },
);

$build->create_build_script;

__END__
