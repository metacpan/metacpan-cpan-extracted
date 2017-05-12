
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'GD::Graph::ohlc',
    'VERSION_FROM'  => 'ohlc.pm',

    'PREREQ_PM'     => { 
        'GD::Graph' => 0,
    },

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.006001,
            META_MERGE => {
                keywords => [qw(graph open close)],
                resources=> {
                    repository => 'http://github.com/jettero/gd--graph--ohlc/',
                },
            },

        LICENSE	=> 'LGPL',
    ) : ()),

    # clean => { FILES => 'blargorious' },
);
