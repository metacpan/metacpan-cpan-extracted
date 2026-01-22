use ExtUtils::MakeMaker;

require 5.016;

use IO::Handle;

my $version  = '4.02';
my $git      = "https://github.com/markov2/perl5-Mail-Message";
my $publish  = "../public_html/mail-message";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.05,
	first_year    => 2001,
	email         => "markov\@cpan.org",

	include  => [
		'../MIME-Types',
 		'../Mail-Box',
 		'../Mail-Box-Parser-C',
 		'../Mail-Transport',
 		'../MailTools',
 		'../Object-Realize-Later',
 		'../User-Identity',
	],

	use      => [
	],

	parser   => {
		syntax         => 'markov',
		skip_links     => [
			'Mail::Box::Netzwert',
			'Mail::ListDetector',
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
	  {
		# Add real pod to the releases
		format         => 'pod3',
		podtail        => undef,
	  },
 	  # You may add HTML formatters here.
 		  # You may add exporter configurations here.
	],
);

my %requires = (
	'Date::Format'   => 0,
	'Date::Parse'    => 0,
	'Encode'         => 2.26,
	'Encode::Alias'  => 0,
	'Fcntl'          => 0,
	'File::Basename' => 0,
	'File::Copy'     => 0,
	'File::Spec'     => 0.7,
	'File::Temp'     => 0,
	'IO::Scalar'     => 0,
	'IO::Lines'      => 0,
	'List::Util'     => 0,
	'Log::Report'    => '1.42',
	'Mail::Address'  => 2.17,
	'MIME::Base64'   => 0,
	'MIME::QuotedPrint' => 0,
	'MIME::Types'    => 1.004,
	'POSIX'          => 0,
	'Scalar::Util'   => 1.13,
	'Storable'       => 0,
	'String::Print'  => 1.01,
	'Sys::Hostname'  => 0,
	'Time::HiRes'    => 1.51,
	'Time::Zone'     => 0,
	'URI'            => 1.23,
	'User::Identity' => '4.0',
);

# See README.md for uses
my %optional = (
	'HTML::FormatText'  => '2.01',
	'HTML::TreeBuilder' => '3.13',
	'Mail::Box'         => '4.00',
	'Mail::Internet'    => '2.01',
	'Mail::Transport'   => '4.00',
	'MIME::Entity'      => '3.0',
	'Net::Domain'       => 0,
);

WriteMakefile
	NAME       => 'Mail::Message',
	VERSION    => $version,
	AUTHOR     => 'Mark Overmeer <markov@cpan.org>',
	ABSTRACT   => 'Processing MIME messages',
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
