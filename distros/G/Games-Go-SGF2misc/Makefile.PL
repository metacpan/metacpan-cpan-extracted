
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Games::Go::SGF2misc',
    'VERSION_FROM' => 'SGF2misc.pm',
    'PREREQ_PM'    => {

        'Parse::Lex'     => 2.19, # I don't know when the 2.15 test bugs were removed, 2.19 is latest
        'Data::Dumper'   => 0, 
        'Compress::Zlib' => 0,

        'CGI' => 0,

        'Devel::Size'    => 0, 
        'Number::Format' => 0, 
        'Time::HiRes'    => 0,

        ($ENV{SKIP_GD} ? (): ('GD' => 2.12)),
    },

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.006001,
            META_MERGE => {
                keywords => ['go', 'sgf'],
                resources=> { repository => 'http://github.com/jettero/SGF2misc' },
            },

        LICENSE	=> 'GPL',
    ) : ()),
);
