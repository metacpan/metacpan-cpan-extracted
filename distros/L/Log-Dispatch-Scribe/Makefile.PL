use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Log::Dispatch::Scribe',
    AUTHOR              => 'Jon Schutz <jon at jschutz.net>',
    VERSION_FROM        => 'lib/Log/Dispatch/Scribe.pm',
    ABSTRACT_FROM       => 'lib/Log/Dispatch/Scribe.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'Getopt::Long' => 0,
        'Test::More' => 0,
        'Test::Timer' => 0,
        'Test::MockObject' => 0,
	'Log::Dispatch' => 2.00,
	'Pod::Usage' => 0,
    },
    INSTALLDIRS         => 'site',
    EXE_FILES           => [ 'bin/scribe_cat.pl' ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Log-Dispatch-Scribe-*' },
);
