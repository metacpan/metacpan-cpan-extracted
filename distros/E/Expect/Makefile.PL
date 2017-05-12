use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
	NAME         => 'Expect',
	VERSION_FROM => 'lib/Expect.pm',
	PREREQ_PM    => {
		'IO::Tty' => 1.11,
		'IO::Pty' => 1.11,

		# standard modules:
		'POSIX'      => 0,
		'Fcntl'      => 0,
		'Carp'       => 0,
		'IO::Handle' => 0,
		'Exporter'   => 0,
		'Errno'      => 0,
	},
	ABSTRACT_FROM => 'lib/Expect.pm',
	MIN_PERL_VERSION => '5.006000',
	clean        => { 'FILES' => '*.log Expect-*' },
	dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
);

if (eval { ExtUtils::MakeMaker->VERSION(6.3002) }) {
	$conf{LICENSE} = 'perl';
}

if (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
	$conf{META_MERGE} = {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'http://github.com/szabgab/expect.pm.git',
				web  => 'http://github.com/szabgab/expect.pm',
			}
		}
	};
}

my %configure_requires = (
        'ExtUtils::MakeMaker' => '6.64',
);
my %build_requires = ();
my %test_requires = (
		'Test::More'      => '1.00',

		# standard modules:
		'File::Temp' => 0,
);

###   merging data "standard code"
if (eval { ExtUtils::MakeMaker->VERSION(6.52) }) {
	$conf{CONFIGURE_REQUIRES} = \%configure_requires;
} else {
	%{ $conf{PREREQ_PM} } = (%{ $conf{PREREQ_PM} }, %configure_requires);
}

if (eval { ExtUtils::MakeMaker->VERSION(6.5503) }) {
	$conf{BUILD_REQUIRES} = \%build_requires;
} else {
	%{ $conf{PREREQ_PM} } = (%{ $conf{PREREQ_PM} }, %build_requires);
}
if (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
	$conf{TEST_REQUIRES} = \%test_requires;
} else {
	%{ $conf{PREREQ_PM} } = (%{ $conf{PREREQ_PM} }, %test_requires);
}
WriteMakefile(%conf);

