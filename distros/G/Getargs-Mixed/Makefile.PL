use 5.006;
use ExtUtils::MakeMaker;
use File::Spec;

my $source = File::Spec->catfile(qw(lib Getargs Mixed.pm));
my $provides;
my $is_trial;

# Fill in $provides {{{1
eval {	# ignore errors
	require Module::Metadata;
	$provides = Module::Metadata->provides(version => '2', dir => 'lib');
		# Thanks to https://stackoverflow.com/a/28928985/2877364 by LEONT
};

# }}}1
# Fill in $is_trial {{{1
eval {	# ignore errors
	my $version = MM->parse_version($source);
	$is_trial = (index($version||'', '_') != -1);
};
print "TRIAL version\n" if $is_trial;
# }}}1

# Main options for EUMM
my %opts = (
	NAME			=> 'Getargs::Mixed',
	VERSION_FROM	=> $source,
	ABSTRACT_FROM	=> $source,

	LICENSE			=> 'perl_5',
	AUTHOR			=> 'Andrew Sterling Hanenkamp <hanenkamp@cpan.org>',

	MIN_PERL_VERSION=> '5.006',
	PREREQ_PM => {
		'Carp'		=> '0',
		'Exporter'	=> '0',
		'strict'	=> '0',
		'warnings'	=> '0',
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker'	=> '0',
		'File::Spec'			=> '3.2701',	# for a Win32 bugfix
	},
	# Note: for the sake of ExtUtils::MakeMaker < 6.63_03, don't use
	# TEST_REQUIRES.  Put test requirements in PREREQ_PM instead.  See, e.g.,
	# https://metacpan.org/source/CXW/List-AutoNumbered-0.000005/Makefile.PL#L202
	# for documentation links.

	META_MERGE => {
		'meta-spec'	=> { version => 2 },

		resources	=> {
			# The code is on GitHub (but we'll take bug reports on RT, too)
			bugtracker	=> {
				web	=> 'https://github.com/cxw42/Getargs-Mixed/issues',
			},

			repository => {
				type	=> 'git',
				url		=> 'https://github.com/cxw42/Getargs-Mixed.git',
				web		=> 'https://github.com/cxw42/Getargs-Mixed',
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

	}, # META_MERGE

	dist	=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean	=> { FILES => 'Getargs-Mixed-*' },
); # %opts

$opts{META_MERGE}->{release_status} = 'testing' if $is_trial;

WriteMakefile(%opts);
# vi: set fdm=marker: #
