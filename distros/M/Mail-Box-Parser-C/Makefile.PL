use ExtUtils::MakeMaker;

require 5.016;

#!!! Change VERSION in lib/Mail/Box/Parser/C.pm

my $git      = "https://github.com/markov2/perl5-Mail-Box-Parser-C";
my $publish  = "../public_html/mail-box-parser-c";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.05,
	first_year => 2002,
	email    => "markov\@cpan.org",

	include  => [
		'../Mail-Message',   # for Mail::Box::Parser
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

	generate => [
	  {	format         => 'pod3',
		podtail        => undef,
	  },
	],
);

my %requires = (
	'Mail::Message' => '3.0, <4.0',
);

WriteMakefile
	NAME          => 'Mail::Box::Parser::C',
	VERSION_FROM  => 'lib/Mail/Box/Parser/C.pm',
	ABSTRACT      => 'Parse mbox files with XS',
	AUTHOR        => 'Mark Overmeer',
	LICENSE       => 'perl_5',

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
				},
			},
		},

		# You may use multiple set-ups, see "oodist --make"
		x_oodist => \%oodist,
	};
