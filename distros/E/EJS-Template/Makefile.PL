use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'EJS::Template',
    AUTHOR              => q{Mahiro Ando <mahiro@cpan.org>},
    VERSION_FROM        => 'lib/EJS/Template.pm',
    ABSTRACT_FROM       => 'lib/EJS/Template.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'IO::Scalar'  => 0,
        'JE'          => 0,
        'Test::More'  => 0,
        'URI::Escape' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'EJS-Template-*' },
);
