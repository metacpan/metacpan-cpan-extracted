use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Markdown::ODF',
    AUTHOR              => q{Andy Beverley <andy@andybev.com>},
    VERSION_FROM        => 'lib/Markdown/ODF.pm',
    ABSTRACT_FROM       => 'lib/Markdown/ODF.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'MIT')
      : ()),
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'File::Temp' => 0,
    },
    PREREQ_PM => {
        'Carp' => 0,
        'Markdown::Parser' => 0,
        'Markdown::Parser::Document' => 0,
        'Moo' => 0,
        'ODF::lpOD' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Markdown-ODF*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/Amtivo-Group/Markdown-ODF',
            bugtracker => 'https://github.com/Amtivo-Group/Markdown-ODF/issues',
            homepage   => 'https://github.com/Amtivo-Group/Markdown-ODF/',
        },
    },
);
