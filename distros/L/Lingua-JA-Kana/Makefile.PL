#
# $Id: Makefile.PL,v 0.2 2011/06/10 10:23:43 dankogai Exp $
#
use 5.008001; # needs perl 5.8.1 or better
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::JA::Kana',
    AUTHOR              => 'Dan Kogai <dankogai@dan.co.jp>',
    VERSION_FROM        => 'lib/Lingua/JA/Kana.pm',
    ABSTRACT_FROM       => 'lib/Lingua/JA/Kana.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Encode'     => 2.00,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lingua-JA-Kana-*' },
);
