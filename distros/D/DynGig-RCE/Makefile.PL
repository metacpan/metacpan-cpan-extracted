use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DynGig::RCE',
    AUTHOR              => 'Kan Liu <kan@cpan.org>',
    VERSION_FROM        => 'lib/DynGig/RCE.pm',
    ABSTRACT_FROM       => 'lib/DynGig/RCE.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp' => 0,
        'Compress::Zlib' => 0,
        'DynGig::Util' => 1.00,
        'File::Spec' => 0,
        'Socket' => 0,
        'Sys::Hostname' => 0,
        'Thread::Semaphore' => 2.12,
        'YAML::XS' => 0.38,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DynGig-RCE-*' },
);
