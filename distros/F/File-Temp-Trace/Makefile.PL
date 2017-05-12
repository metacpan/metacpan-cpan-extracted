use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'File::Temp::Trace',
    AUTHOR              => q{Robert Rothenberg <rrwo@cpan.org>},
    VERSION_FROM        => 'lib/File/Temp/Trace.pm',
    ABSTRACT_FROM       => 'lib/File/Temp/Trace.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'Attribute::Handlers' => 0,
	'Carp' => 0,
        'File::Path' => 0,
	'File::Spec' => 0,
	'File::Temp' => 0,
	'IO::File' => 0,
	'overload'   => 0,
	'Scalar::Util' => 0,
	'self' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-Temp-Trace-*' },
);
