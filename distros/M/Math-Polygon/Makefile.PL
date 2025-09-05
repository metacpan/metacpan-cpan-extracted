use ExtUtils::MakeMaker;

require 5.016;

# Use command 'oodist' to produce your whole software release.
my $git      = "https://github.com/markov2/perl5-Math-Polygon";
my $publish  = "../public_html/math-polygon";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.03,
	first_year    => 2004,
	email    => "markov\@cpan.org",

	include  => [
	],

	use      => [
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

	generate => [
	  {	# Add real pod to the releases
		format         => 'pod3',
		podtail        => undef,
	  },
 	  # You may add HTML formatters here.
 	  # You may add exporter configurations here.
	],
);

WriteMakefile
	NAME        => 'Math::Polygon',
	VERSION     => '2.00',
	PREREQ_PM   => {
		Test::More    => 0.47,
		Scalar::Util  => 1.13,
		Math::Trig    => 0,
		Log::Report   => 0,
	},
	AUTHOR      => 'Mark Overmeer <markov@cpan.org>',
	ABSTRACT    => 'basic polygon calculations',
	LICENSE     => 'perl_5',

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
					'OODoc' => 3.03,
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
