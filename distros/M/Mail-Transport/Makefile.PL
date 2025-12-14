use ExtUtils::MakeMaker;

require 5.016;

use IO::Handle;

# Use command 'oodist' to produce your whole software release.
my $version  = '4.01';
my $git      = "https://github.com/markov2/perl5-Mail-Transport";
my $publish  = "../public_html/mail-transport";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.05,
	first_year => 2001,
	email    => "markov\@cpan.org",

	include  => [
		'../Mail-Box-IMAP4',
 		'../Mail-Box-POP3',
 		'../Mail-Message',
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
		format         => 'pod3',
		podtail        => undef,
	}, ],
);

my %requires = (
	'Carp'           => 0,
	'Errno'          => 0,
	'File::Spec'     => 0.7,
	'IO::Socket'     => 0,
	'List::Util'     => 0,
	'Log::Report'    => 1.42,
	'Net::SMTP'      => 0,
	'String::Print'  => 1.01,

	'Mail::Reporter' => '4.00',
);

my %optional;

WriteMakefile
	NAME       => 'Mail::Transport',
	VERSION    => $version,
	AUTHOR     => 'Mark Overmeer',
	ABSTRACT   => 'Email message exchange',
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
				requires   => \%requires,
				recommends => \%optional,
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
