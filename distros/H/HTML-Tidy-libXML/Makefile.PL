#
# $Id: Makefile.PL,v 0.1 2009/02/21 11:18:30 dankogai Exp $
#
use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::Tidy::libXML',
    AUTHOR              => 'Dan Kogai <dankogai@dan.co.jp>',
    VERSION_FROM        => 'lib/HTML/Tidy/libXML.pm',
    ABSTRACT_FROM       => 'lib/HTML/Tidy/libXML.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'XML::LibXML' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-Tidy-libXML-*' },
);
