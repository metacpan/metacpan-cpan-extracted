use strict;
use warnings;
use ExtUtils::MakeMaker;

eval {
    require threads;
};
die "threads are required for Distributed::Process to work" if $@;

WriteMakefile(
    NAME                => 'Distributed::Process',
    AUTHOR              => 'Cédric Bouvier <cbouvi@cpan.org>',
    VERSION_FROM        => 'lib/Distributed/Process.pm',
    ABSTRACT_FROM       => 'lib/Distributed/Process.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Time::HiRes' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Distributed-Process-*' },
);
