use 5.008;
use ExtUtils::MakeMaker;
use File::Spec;

my $source = File::Spec->catfile(qw(lib Getargs Mixed.pm));

# Module metadata {{{1
my $provides;
eval {
	require Module::Metadata;
	$provides = Module::Metadata->provides(version => '2', dir => 'lib');
		# Thanks to https://stackoverflow.com/a/28928985/2877364 by LEONT
};
# }}}1

# Main options for EUMM
my %opts = (
	NAME			=> 'Getargs::Mixed',
	VERSION_FROM	=> $source,
	ABSTRACT_FROM	=> $source,

	LICENSE			=> 'perl_5',
	AUTHOR			=> 'Andrew Sterling Hanenkamp <hanenkamp@cpan.org>',

	MIN_PERL_VERSION=> '5.008',
	PREREQ_PM => {
		'Carp' => '0',
		'Exporter' => '0',
		'strict' => '0',
		'warnings' => '0',
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
		'File::Spec' => '3.2701',	# for a Win32 bugfix
	},

	META_MERGE => {
		'meta-spec' => { version => 2 },

		resources => {
			# The code is on GitHub (but we'll take bug reports on RT, too)
			bugtracker  => {
				web	=> 'https://github.com/cxw42/Getargs-Mixed/issues',
			},

			repository => {
				type => 'git',
				url  => 'https://github.com/cxw42/Getargs-Mixed.git',
				web  => 'https://github.com/cxw42/Getargs-Mixed',
			},
		},

		x_contributors => [
			# Use CPAN emails so MetaCPAN will pick them up.
			'Andrew Sterling Hanenkamp <hanenkamp@cpan.org>',
			'Christopher White <cxw@cpan.org>',
		],

		$provides ? (provides => $provides) : (),

		prereqs => {
			develop => {
				recommends => {
					'Module::Metadata' => '1.000016',
				},
			},
		},

	},

	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'Getargs-Mixed-*' },
);

WriteMakefile(%opts);
