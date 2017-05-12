###########################################################################
#
#   Makefile.PL
#
#   Copyright (C) 1999 Raphael Manfredi.
#   Copyright (C) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Log::Agent',
    VERSION_FROM => 'Agent.pm',
    PREREQ_PM => {
        'Tie::Array' => 0,
        'Test::More' => 0,
    },
    clean => {
        FILES => '*~ *.err *.out Agent/*~ t*~ t/*.err t/*.out',
    },
    ($] < 5.008_001 ? () : ( NO_META => 1 ))
);

