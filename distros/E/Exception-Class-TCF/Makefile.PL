# $Id: Makefile.PL 1662 2006-07-14 07:26:24Z rvosa $
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Exception::Class::TCF',
    AUTHOR              => 'Rutger Vos <rvosa@sfu.ca>',
    VERSION_FROM        => 'lib/Exception/Class/TCF.pm',
    PREREQ_PM           => { 'Exception::Class' => 1.23 },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Exception-Class-TCF-*' },
);
