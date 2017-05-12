# -*- mode: perl; coding: us-ascii-unix -*-

use 5.006;              # required version of Perl
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings

use ExtUtils::MakeMaker;

print <<"EOF";

########################################################################
#
# This module is now redundant. The functions implemented in this module
# are now implemented as methods in Math::BigInt and Math::Float. If you
# have a recent version of these modules, you already have the methods
# available to you.
#
# See the number splitting methods nparts() and eparts(), and maybe also
# sparts(), and dparts().
#
# Also see the string formatting methods bnstr() and bestr(), and maybe
# also bsstr() and bdstr().
#
########################################################################

EOF

ExtUtils::MakeMaker::prompt("Continue anyway? ", "y") =~ /^y/i
  or die "FATAL: User aborted configuration of Math::BigInt::Parts.\n";

WriteMakefile
  (
   NAME             => 'Math::BigInt::Parts',
   AUTHOR           => 'Peter John Acklam <pjacklam@online.no>',
   VERSION_FROM     => 'lib/Math/BigInt/Parts.pm',
   ABSTRACT_FROM    => 'lib/Math/BigInt/Parts.pm',
   PREREQ_PM        => {
                        #'ExtUtils::MakeMaker' => 6.58,
                        'Test::More'          => 0.47,
                        'Math::BigInt'        => 1.999719,
                       },
   'LICENSE'            => 'perl_5',
   'LIBS'               => [''],        # e.g., '-lm'
   'DEFINE'             => '',          # e.g., '-DHAVE_SOMETHING'
   'INC'                => '',          # e.g., '-I/usr/include/other'
   'SIGN'               => 1,
   dist             => {
                        COMPRESS => 'gzip -9f',
                        SUFFIX => '.gz',
                       },
   clean            => {
                        FILES => 'Math-BigInt-Parts-*',
                       },
  );
