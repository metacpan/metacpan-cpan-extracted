use ExtUtils::MakeMaker;

use 5.016;

# Use command 'oodist' to produce your whole software release.
my $version = '1.08';
my $git      = "https://github.com/markov2/perl5-Log-Report-Optional";
my $publish  = "../public_html/log-report-optional";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.04,
	first_year => 2013,
	email    => "markov\@cpan.org",

	include  => [
	],

	use      => [
		'../String-Print',
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

WriteMakefile
	NAME      => 'Log::Report::Optional',
	VERSION   => $version,

	PREREQ_PM => +{
		'Test::More'    => '0.86',
		'String::Print' => '0.91',
		# Optional dependency to Log::Report handled in ::Optional.  It is hard
		# to make that work automatically, where Perl's install tools cannot
		# handle recursive dependencies.
	},

	AUTHOR    => 'Mark Overmeer <mark@overmeer.net>',
	ABSTRACT  => 'Log::Report in its lightest form',
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
					'OODoc'      => 3.03,
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
