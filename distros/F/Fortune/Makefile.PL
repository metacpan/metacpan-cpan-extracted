# $Id: Makefile.PL,v 1.1 1999/02/20 18:53:06 greg Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => 'Fortune',
    'VERSION_FROM' => 'Fortune.pm',
    'dist'      => { COMPRESS => "gzip", SUFFIX => "gz" },
);
