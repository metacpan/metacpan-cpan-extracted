use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'GearmanX::Starter',
    AUTHOR              => q{Douglas Wilson <dougw@cpan.org>},
    VERSION_FROM        => 'lib/GearmanX/Starter.pm',
    ABSTRACT_FROM       => 'lib/GearmanX/Starter.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Gearman::XS' => "0.08",
        'Perl::Unsafe::Signals' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'GearmanX-Starter-*' },
);
