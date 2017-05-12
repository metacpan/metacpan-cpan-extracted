use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DomainOperations',
    AUTHOR              => q{"abhishek jain" <"goyali@cpan.org">},
    VERSION_FROM        => 'lib/DomainOperations.pm',
    ABSTRACT_FROM       => 'lib/DomainOperations.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DomainOperations-*' },
);
