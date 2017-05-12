use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'IMDB::Local',
    AUTHOR           => q{jerryv <jerryv@cpan.org>},
    VERSION_FROM     => 'lib/IMDB/Local.pm',
    ABSTRACT_FROM    => 'lib/IMDB/Local.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'IO::File' => 0.0,
        'Text::Unidecode' => 0.0,
        'Class::MethodMaker' => 0.0,
        'Class::Accessor' => 0.0,
        'LWP' => 0.0,
        'DBI' => 0.0,
        'DBD::SQLite' => 0.0,
        'Time::HiRes' => 0.0,
	'IO::Uncompress::Gunzip' => 0.0,
	'Term::ProgressBar' => 2.0,
    },
    EXE_FILES => [ "script/imdb-local.pl", "script/imdb-title.pl" ],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'IMDB-Local-*' },
);
