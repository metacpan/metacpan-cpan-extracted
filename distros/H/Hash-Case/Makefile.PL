use ExtUtils::MakeMaker;

use 5.016;

use warnings;
use strict;

# Use command 'oodist' to produce your whole software release.
my $version  = '1.07',
my $git      = "https://github.com/markov2/perl5-Hash-Case";
my $publish  = "../public_html/hash-case";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.06,
	first_year => 2002,
	email    => "markov\@cpan.org",

	include  => [
	],

	use      => [
	],

	parser   => {
		syntax         => 'markov',
		skip_links     => [
			'Tie::StdHash',
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
	],
);

my %requires = (
	'Tie::Hash'        => 0,
#	'Tie::StdHash'     => 0,  # hidden component of Tie::Hash
	'Carp'             => 0,
);

WriteMakefile
	NAME		 => 'Hash::Case',
	VERSION      => $version,
	AUTHOR       => 'Mark Overmeer <markov@cpan.org>',
	ABSTRACT     => 'Play trics with HASH keys',
	LICENSE      => 'perl_5',

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
				recommends => {},
				suggests   => {},
			},
			develop => {
				requires => {
					'OODoc' => '3.00',
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
