use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::PTD::More',
    AUTHOR              => q{Nuno Carvalho <smash@cpan.org>},
    VERSION_FROM        => 'lib/Lingua/PTD/More.pm',
    ABSTRACT_FROM       => 'lib/Lingua/PTD/More.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Lingua::PTD' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lingua-PTD-More-*' },
);
