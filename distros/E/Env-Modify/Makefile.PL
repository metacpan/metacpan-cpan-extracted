#! perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $NO_INDEX = {};

WriteMakefile(
    NAME                => 'Env::Modify',
    AUTHOR              => q{Marty O'Brien <mob@cpan.org>},
    VERSION_FROM        => 'lib/Env/Modify.pm',
    ABSTRACT_FROM       => 'lib/Env/Modify.pm',
    (eval $ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    (eval $ExtUtils::MakeMaker::VERSION >= 6.46
      ? ('META_MERGE'   => { no_index => $NO_INDEX })
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Shell::GetEnv' => '0.09',
        'File::Temp'    => 0,
        'File::Spec::Functions' => 0,
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => '5.008001',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Env-Modify-* t/*.out.* MYMETA.*' },
    test                => { TESTS => "t/*.t" },
);
