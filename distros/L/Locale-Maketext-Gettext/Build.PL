#! /usr/bin/perl -w
use strict;
use Module::Build;

my $build = Module::Build->new(
    dist_name       => "Locale-Maketext-Gettext",
    dist_version    => "1.30",
    dist_abstract   => "Joins gettext and Maketext frameworks",
    dist_author     => "imacat <imacat\@mail.imacat.idv.tw>",
    license         => "perl",
    sign            => 1,
    
    script_files    => [ "script/maketext" ],
    requires        => {
        "perl"          => "5.8.0",
    },
    add_to_cleanup	=> [ "t/test_native.po", "t/locale/en/LC_MESSAGES/test_native.mo" ],
);

$build->create_build_script;

__END__
