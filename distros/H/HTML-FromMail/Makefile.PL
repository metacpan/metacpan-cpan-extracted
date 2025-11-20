use ExtUtils::MakeMaker;

require 5.016;

use IO::Handle;

my $version  = '3.00';
my $git      = "https://github.com/markov2/perl5-HTML-FromMail";
my $publish  = "../public_html/html-frommail";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.05,
	first_year    => 2003,
	email         => "markov\@cpan.org",

	include  => [
	],

	use      => [
	],

	parser   => {
		syntax         => 'markov',
		skip_links     => [
			'Template::Magic',
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
	'Mail::Box'        => 2.051,
	'HTML::FromText'   => 2.03,
	'OODoc::Template'  => 0.01,  # default template system
);

# See README.md for uses
my %optional = (
	'Template::Magic'  => '1.02',
	'Image::Magick'    => '5.0',
);

WriteMakefile
	NAME       => 'HTML::FromMail',
	VERSION    => $version,
	AUTHOR     => 'Mark Overmeer <markov@cpan.org>',
	ABSTRACT   => 'Convert E-mail into HTML',
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
				optional => \%optional,
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
