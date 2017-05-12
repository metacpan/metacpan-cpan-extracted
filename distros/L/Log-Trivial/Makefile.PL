# $Id: Makefile.PL 61 2014-05-23 11:04:17Z adam $

use ExtUtils::MakeMaker;
use strict;
use 5.010;

if ($^O !~ /linux/i) {
    print <<"WARNING";

################################################
# The module has not been fully tested on old  #
# versions of Perl, it may or may not work.    #
# User beware!                                 #
#                                              #
# This module uses the POSIX open O_SYNC flag. #
# This flag is not supported on all systems.   #
################################################

WARNING
}

WriteMakefile(
    'NAME'          => 'Log::Trivial',
    'VERSION_FROM'  => 'lib/Log/Trivial.pm',
    'PREREQ_PM'     => {},
    'PL_FILES'      => {},
     dist           => {
       COMPRESS      => 'gzip -9f',
       SUFFIX        => 'gz'
       },
      ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/Log/Trivial.pm',
       AUTHOR     => 'Dr A. J. Trickett <atrickett@cpan.org>') : ()),
);
