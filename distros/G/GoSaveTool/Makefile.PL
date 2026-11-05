use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'GoSaveTool',
    AUTHOR           => 'GoSaveTool <https://www.gosavetool.com/>',
    VERSION_FROM     => 'lib/GoSaveTool/Text.pm',
    ABSTRACT         => 'SRT and WebVTT subtitle tools, word count, social media limits and case changes',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.64' },
    TEST_REQUIRES    => { 'Test::More' => '0.88' },
    PREREQ_PM        => { 'Unicode::Normalize' => 0, 'Carp' => 0, 'Exporter' => '5.57' },
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://www.gosavetool.com/',
            repository => { type => 'git', url => 'https://github.com/mitolocya/gosavetool-perl.git', web => 'https://github.com/mitolocya/gosavetool-perl' },
            bugtracker => { web => 'https://www.gosavetool.com/contact' },
        },
        keywords => [qw(subtitles srt webvtt captions word-count character-count title-case slug)],
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'GoSaveTool-*' },
);
