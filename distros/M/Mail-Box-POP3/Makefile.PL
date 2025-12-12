use ExtUtils::MakeMaker;

require 5.016;

use warnings;
use strict;

# Use command 'oodist' to produce your whole software release.
my $version = '4.000';
my $git      = "https://github.com/markov2/perl5-Mail-Box-POP3";
my $publish  = "../public_html/mail-box-pop3";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.05,
	first_year    => 2001,
	email         => "markov\@cpan.org",

	include  => [
		'../Mail-Box',
 		'../Mail-Message',
 		'../Mail-Transport',
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
 	  # You may add HTML formatters here.
 		  # You may add exporter configurations here.
	],
);

my %requires = (
	'Digest::MD5'     => 0,
	'IO::Socket'      => 0,
	'IO::Socket::IP'  => 0,
	'List::Util'      => 0,
	'Log::Report'     => '1.42',
	'Socket'          => 0,

	'Mail::Box::FastScalar'        => '4.0',
	'Mail::Box::Net'               => '4.0',
	'Mail::Box::Test'              => '4.0',
	'Mail::Box::Parser::Perl'      => '4.0',
	'Mail::Transport::Receive'     => '4.0',
	'Mail::Reporter'               => '4.0',
);

WriteMakefile
	NAME       => 'Mail::Box::POP3',
	VERSION    => $version,
	AUTHOR     => 'Mark Overmeer',
	ABSTRACT   => 'Mail::Box connector via POP3',
	LICENSE    => 'perl_5',

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
				},
			},
			test => {
				requires => {
					'Test::More' => 1.00,
					'Test::Pod'  => 1.00,
					'File::Spec' => 0,
					'File::Basename' => 0,
				},
			},
		},

		# You may use multiple set-ups, see "oodist --make"
		x_oodist => \%oodist,
	};
