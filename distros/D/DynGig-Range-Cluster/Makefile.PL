use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DynGig::Range::Cluster',
    AUTHOR              => 'Kan Liu <kan@cpan.org>',
    VERSION_FROM        => 'lib/DynGig/Range/Cluster.pm',
    ABSTRACT_FROM       => 'lib/DynGig/Range/Cluster.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp' => 0,
        'Compress::Zlib' => 0,
        'Digest::MD5' => 0,
        'DynGig::Multiplex' => 1.00,
        'DynGig::Util' => 1.00,
        'File::Spec' => 0,
        'YAML::XS' => 0.38,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DynGig-Range-Cluster-*' },
);
