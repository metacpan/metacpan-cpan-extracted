use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'File::Tail::Scribe',
    AUTHOR              => 'Jon Schutz <jon at jschutz.net>',
    VERSION_FROM        => 'lib/File/Tail/Scribe.pm',
    ABSTRACT_FROM       => 'lib/File/Tail/Scribe.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'File::Basename' => 0,
	'File::Spec::Functions' => 0,
	'File::Tail::Dir' => 0,
	'File::Temp' => 0,
	'FindBin' => 0,
	'Getopt::Long' => 0,
	'Log::Dispatch::Scribe' => 0,
	'Moose' => 0,
	'POSIX' => 0,
	'Pod::Usage' => 0,
	'Sys::Hostname' => 0,
        'Test::MockObject' => 0,
        'Test::More' => 0,
    },
    INSTALLDIRS         => 'site',
    EXE_FILES           => [ 'bin/tail_to_scribe.pl' ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-Tail-Scribe-*' },
);
