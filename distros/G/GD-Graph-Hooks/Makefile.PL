
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'GD::Graph::Hooks',
    'VERSION_FROM'  => 'Hooks.pm',

    'PREREQ_PM'     => { 
        'GD::Graph' => 0,
    },

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.006001,
            META_MERGE => {
                resources=> {
                    repository => 'http://github.com/jettero/gd--graph--hooks/',
                },
            },

        LICENSE	=> 'perl-artistic',
    ) : ()),

    # clean => { FILES => 'blargorious' },
);
