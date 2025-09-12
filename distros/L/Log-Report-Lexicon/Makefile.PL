use ExtUtils::MakeMaker;

use 5.016;

# Use command 'oodist' to produce your whole software release.
my $version  = '1.14';
my $git      = "https://github.com/markov2/perl5-Log-Report-Lexicon";
my $publish  = "../public_html/log-report-lexicon";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.03,
	first_year    => 2007,
	email         => "markov\@cpan.org",

	include  => [
		'../String-Print',
		'../Log-Report-Optional',
	],

	use      => [
		'../Log-Report',
		'../Log-Report-Template',
	],

	parser   => {
		syntax         => 'markov',
		skip_links     => [ ],
		pmhead         => undef,
	},

	tests    => {
	},

	release  => {
		publish        => "$publish/source",
	},

	raw      => {
		publish        => "$publish/raw",
	},

	generate => [ {
		# Add real pod to the releases
		format         => 'pod3',
		podtail        => undef,
	  },
 	  # You may add HTML formatters here.
 	  # You may add exporter configurations here.
	],
);

my %prereq  = (
	'Test::More'              => '0.86',
	'Data::Dumper'            => 0,
	'Fcntl'                   => 0,
	'File::Basename'          => 0,
	'File::Find'              => 0,
	'File::Spec'              => 0,
	'File::Temp'              => 0,
	'IO::File'                => 0,
	'List::Util'              => 0,
	'Scalar::Util'            => 0,
	'Log::Report'             => 1.40,
	'Pod::Usage'              => 0,
	'POSIX'                   => 0,
	'Encode'                  => 0,

  	# sometimes needed, dependencies too large
  	# PPI
  	# Locale::gettext
);

$prereq{ 'Win32::TieRegistry' } = 0.24
    if $^O eq 'MSWin32';

WriteMakefile
	NAME      => 'Log::Report::Lexicon',
	VERSION   => $version,
	PREREQ_PM => \%prereq,
	EXE_FILES => [ 'bin/xgettext-perl' ],

	AUTHOR    => 'Mark Overmeer <markov@cpan.org>',
	ABSTRACT  => 'Log::Report translation table management',
	LICENSE   => 'perl_5',

	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => "$git.git",
				web  => $git,
			},
			homepage => $homepage,
			license  => [ 'http//dev.perl.org/licenses/' ],
		},
		prereqs => {
			develop => {
				requires => {
					'OODoc' => '3.00',
				}
			},
			test => {
				requires => {
					'Test::More' => 1.00,
					'Test::Pod'  => 1.00,
				}
			},
		},

		# You may use multiple set-ups, see "oodist --make"
		x_oodist => \%oodist,
	};

# for translation tables
#linkext::
#	bin/xgettext-perl --mode=VERBOSE -p lib/Log/Report/messages lib bin
