# $Id: Makefile.PL,v 1.2 2014-10-23 12:21:56 swaj Exp $
use 5.0008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Digest::PSHA',
    VERSION_FROM      => 'lib/Digest/PSHA.pm', # finds $VERSION
    PREREQ_PM         => {
        Digest::SHA  => 1.1,
        Digest::HMAC => 1.0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Digest/PSHA.pm', # retrieve abstract from module
       AUTHOR         => 'Alexey Semenoff [http://swaj.net]') : ()),
);
