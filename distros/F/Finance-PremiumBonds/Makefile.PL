# $Id$

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Finance::PremiumBonds',
    AUTHOR              => 'David Precious <davidp@preshweb.co.uk>',
    VERSION_FROM        => 'lib/Finance/PremiumBonds.pm',
    ABSTRACT_FROM       => 'lib/Finance/PremiumBonds.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'LWP::UserAgent' => 0,
        'JSON' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Finance-PremiumBonds-*' },

    # include the LICENSE param, as long as EU::MM is new enough to support it:
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? (LICENSE => "perl") : () ),
);
