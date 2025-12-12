use ExtUtils::MakeMaker;

require 5.016;

use warnings;
use strict;

# Use command 'oodist' to produce your whole software release.
my $version  = '4.000';
my $git      = "https://github.com/markov2/perl5-Mail-Box-IMAP4";
my $publish  = "../public_html/mail-box-imap4";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.05,
	first_year    => 2001,
	email         => "perl\@overmeer.net",

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
		format         => 'pod3',
		podtail        => undef,
	  },
 	  # You may add HTML formatters here.
 		  # You may add exporter configurations here.
	],
);

my %prereq = (
	'Date::Parse'      => 0,
	'Digest::HMAC_MD5' => 0,
	'Digest::MD5'      => 0,
	'File::Compare'    => 0,
	'File::Copy'       => 0,
	'File::Spec'       => 0,
	'File::Temp'       => 0.19,
	'IO::Socket::IP'   => 0,
	'List::Util'       => 0,
	'Log::Report'      => '1.42',
	'Mail::IMAPClient' => '3.42',
	'Scalar::Util'     => 0,

	'Mail::Box'                    => '4.0',
	'Mail::Box::Manage::User'      => '4.0',
	'Mail::Box::Net'               => '4.0',
	'Mail::Box::Search'            => '4.0',
	'Mail::Message'                => '4.0',
	'Mail::Message::Body::Lines'   => '4.0',
	'Mail::Message::Head::Complete'=> '4.0',
	'Mail::Message::Head::Delayed' => '4.0',
	'Mail::Server'                 => '4.0',
	'Mail::Transport::Receive'     => '4.0',
);

WriteMakefile
	NAME       => 'Mail::Box::IMAP4',
	VERSION    => $version,
	AUTHOR     => 'Mark Overmeer',
	ABSTRACT   => 'Mail::Box connector via IMAP4',
	PREREQ_PM  => \%prereq,
	LICENSE    => 'perl_5',

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
					'Mail::Box::Test' => '4.0',
				}
			},
		},

		# You may use multiple set-ups, see "oodist --make"
		x_oodist => \%oodist,
	};
