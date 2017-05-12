use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'IBM::V7000',
    AUTHOR              => q{Luke Poskitt <lukep@deakin.edu.au>},
    VERSION_FROM        => 'lib/IBM/V7000.pm',
    ABSTRACT_FROM       => 'lib/IBM/V7000.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Net::OpenSSH' => 0,
        'IBM::StorageSystem' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IBM-V7000-*' },
);
