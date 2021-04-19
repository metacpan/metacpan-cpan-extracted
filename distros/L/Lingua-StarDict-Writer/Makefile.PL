use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Lingua::StarDict::Writer',
    AUTHOR           => q{Nikolay Shaplov <dhyan@nataraj.su>},
    VERSION_FROM     => 'lib/Lingua/StarDict/Writer.pm',
    ABSTRACT_FROM    => 'lib/Lingua/StarDict/Writer.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.008',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0' , 'Test::Files' => '0', 'File::Temp' => 0, 'Test::Fatal' => 0
    },
    PREREQ_PM => {
        'Path::Tiny'             => '0',
        'Unicode::UTF8'          => '0',
        'Time::Piece'            => '0',
        'Moo'                    => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Lingua-StarDict-Writer-*' },

    META_MERGE    => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://gitlab.com/dhyannataraj/lingua-stardict-writer-perl.git',
                 web  => 'https://gitlab.com/dhyannataraj/lingua-stardict-writer-perl',
             },
             bugtracker => {web => 'https://gitlab.com/dhyannataraj/lingua-stardict-writer-perl/-/issues'},
#             homepage   => '',
         },
    },
);
