use ExtUtils::MakeMaker;

use 5.016;

# Use command 'oodist' to produce your whole software release.
my $version  = '2.30';              #!!! scanned by bin/collect_types
my $webpages = "../public_html";
my $git      = "https://github.com/markov2/perl5-MIME-Types";
my $publish  = "../public_html/mime-types";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.05,
	first_year    => 1999,
	email         => "markov\@cpan.org",

	include  => [
	],

	use      => [
	],

	parser   => {
		syntax         => 'markov',
		skip_links     => [
		],
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
 		  # You may add exporter configurations here.
	],
);

my %requires = (
   	'File::Spec'     => 0,
   	'File::Basename' => 0,
   	'List::Util'     => 0,
);

WriteMakefile
	NAME      => 'MIME::Types',
	VERSION   => $version,
	AUTHOR    => 'Mark Overmeer <mark@overmeer.net>',
	ABSTRACT  => 'Definition of MIME types',
	LICENSE   => 'perl_5',

	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => "$git.git",
				web  => $git,
			},
			bugtracker => {
				web  => "$git/issues",
			},
			homepage => $homepage,
			license  => [ 'http//dev.perl.org/licenses/' ],
		},
		prereqs => {
			runtime => {
				requires => \%requires,
			},
			develop => {
				requires => {
					'OODoc' => '3.00',
					'File::Slurper' => 0,
				},
			},
			test => {
				requires => {
					'Test::More' => 1.00,
					'Test::Pod'  => 1.00,
				},
			},
		},

		# You may use multiple set-ups, see "oodist --make"
		x_oodist => \%oodist,
	};
