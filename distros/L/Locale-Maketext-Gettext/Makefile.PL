#! /usr/bin/perl -w
require 5.008;
use strict;
use ExtUtils::MakeMaker;

# LICENSE is only availabe since ExtUtils::MakeMaker 6.30_01
use vars qw(%license $eummver);
%license = qw();
$eummver = $ExtUtils::MakeMaker::VERSION;
$eummver =~ s/_//;
%license = (LICENSE => "perl") if $eummver > 6.30;

WriteMakefile(
    NAME        => "Locale-Maketext-Gettext",
    VERSION     => "1.30",
    ABSTRACT    => "Joins gettext and Maketext frameworks",
    AUTHOR      => "imacat <imacat\@mail.imacat.idv.tw>",
    %license,
    PREREQ_PM   => { },
    SIGN        => 1,
    
    EXE_FILES   => [ "script/maketext" ],
    dist        => {
        COMPRESS    => "gzip -9",
        SUFFIX      => ".gz",
    },
    clean		=> {
        FILES		=> "t/test_native.po t/locale/en/LC_MESSAGES/test_native.mo",
    },
);

__END__
