use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DynGig::CLI',
    AUTHOR              => q{Kan Liu <kan@cpan.org>},
    VERSION_FROM        => 'lib/DynGig/CLI.pm',
    ABSTRACT_FROM       => 'lib/DynGig/CLI.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DynGig-CLI-*' },
);
