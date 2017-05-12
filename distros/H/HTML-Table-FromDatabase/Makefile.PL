# $Id$

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::Table::FromDatabase',
    AUTHOR              => 'David Precious <davidp@preshweb.co.uk>',
    VERSION_FROM        => 'lib/HTML/Table/FromDatabase.pm',
    ABSTRACT_FROM       => 'lib/HTML/Table/FromDatabase.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'HTML::Table' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-Table-FromDatabase-*' },

    META_MERGE => {
        resources => {
            repository => 'https://github.com/bigpresh/HTML-Table-FromDatabase',
            bugtracker => 'https://github.com/bigpresh/HTML-Table-FromDatabase/issues',
            homepage   => 'https://github.com/bigpresh/HTML-Table-FromDatabase/',
        },
    },

    # include the LICENSE param, as long as EU::MM is new enough to support it:
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? (LICENSE => "perl") : () ),
);
