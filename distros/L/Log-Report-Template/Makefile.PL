use ExtUtils::MakeMaker;

use 5.016;
use warnings;
use strict;

my $version  = '1.03';

# Use command 'oodist' to produce your whole software release.
my $git      = "https://github.com/markov2/perl5-Log-Report-Template";
my $publish  = "../public_html/log-report-template";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.04,
	first_year => 2017,
	email    => "markov\@cpan.org",

	include  => [
		'../Log-Report',
 		'../Log-Report-Lexicon',
 		'../Log-Report-Optional',
 		'../String-Print',
	],

	use      => [
	],

	parser   => {
		syntax         => 'markov',
		skip_links     => [
			'Dancer2::Config',
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
	  # You may add HTML formatters here.
	  # You may add exporter configurations here.
	],
);

my %prereq  = (
	'Test::More'              => 0.86,
	'Scalar::Util'            => 0,
	'Log::Report'             => 1.40,
	'Log::Report::Lexicon'    => 1.13,
	'Template'                => 2.26,
	'String::Print'           => 0.91,
	'File::Find'              => 0,
);

WriteMakefile
	NAME      => 'Log::Report::Template',
	VERSION   => $version,
	PREREQ_PM => \%prereq,

	AUTHOR    => 'Mark Overmeer <markov@cpan.org>',
	ABSTRACT  => 'template toolkit with translations',
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
#	- PERL5LIB="lib:$PERL5LIB" bin/xgettext-perl --mode=VERBOSE -p lib/Log/Report/messages lib
