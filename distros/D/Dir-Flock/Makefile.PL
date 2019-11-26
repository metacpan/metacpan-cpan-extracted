use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dir::Flock',
    AUTHOR              => q{Marty O'Brien <mob@cpan.org>},
    VERSION_FROM        => 'lib/Dir/Flock.pm',
    ABSTRACT_FROM       => 'lib/Dir/Flock.pm',
    (eval $ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
#    (eval $ExtUtils::MakeMaker::VERSION >= 6.46
#      ? ('META_MERGE'   => { no_index => $NO_INDEX })
#      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Time::HiRes' => '1.92',      # Time::HiRes::stat  required
        'File::Temp' => 0,
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => '5.008001',
    test		=> { TESTS => 't/*.t' },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dir-Flock-* MYMETA.* t/*.out
                                       t/dflock-*' },
);
