#! /usr/bin/perl -w
require 5.008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME        => "Locale::Maketext::Gettext",
    VERSION     => "1.32",
    ABSTRACT    => "Joins gettext and Maketext frameworks",
    AUTHOR      => "imacat <imacat\@mail.imacat.idv.tw>",
    PREREQ_PM   => { },
    LICENSE     => "perl",
    SIGN        => 1,
    
    EXE_FILES   => [ "script/maketext" ],
    dist        => {
        COMPRESS    => "gzip -9",
        SUFFIX      => ".gz",
    },
    clean		=> {
        FILES		=> "t/test_native.po t/locale/en/LC_MESSAGES/test_native.mo",
    },

    META_MERGE  => {
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

__END__
