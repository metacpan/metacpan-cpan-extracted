# vi:set syntax=perl:

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Math::Units::PhysicalValue',
    'VERSION_FROM' => 'PhysicalValue.pm',
    'PREREQ_PM'     => { 
        'Number::Format'         => 0,
        'Math::Units'            => 0,
        'Math::Algebra::Symbols' => 0,
        'Math::BigFloat'         => 0,
    },

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.006001,
            META_MERGE => {
                keywords => [qw(units)],
                resources=> {
                    repository => 'http://github.com/jettero/pv/',
                },
            },

        LICENSE	=> 'LGPL',
    ) : ()),
);
