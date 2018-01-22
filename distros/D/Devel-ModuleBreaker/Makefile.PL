use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Devel::ModuleBreaker',
    AUTHOR              => q{Marty O'Brien <mob@cpan.org>},
    VERSION_FROM        => 'lib/Devel/ModuleBreaker.pm',
    ABSTRACT_FROM       => 'lib/Devel/ModuleBreaker.pm',
    (eval $ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => '5.008001',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Devel-ModuleBreaker-* MYMETA.*' },
);
