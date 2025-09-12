use ExtUtils::MakeMaker;

use 5.016;
use warnings;
use strict;

# Use command 'oodist' to produce your whole software release.
my $version  = '1.41';
my $webpages = "../public_html";
my $git      = "https://github.com/markov2/perl5-Log-Report";
my $publish  = "../public_html/log-report";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.04,
	first_year    => 2007,
	email         => "markov\@cpan.org",

	include  => [
		'../Log-Report-Lexicon',
		'../Log-Report-Optional',
		'../Log-Report-Template',
		'../String-Print',
	],

	use      => [
	],

	parser   => {
		syntax         => 'markov',
		skip_links     => [
			'Dancer2::Config',
			'Dancer2::Logger::Syslog',
			'Locale::TextDomain',
			'Log::Dispatch',
			'Log::Dispatch::Output',
			'Log::Log4perl',
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
	  {	format         => 'html',
		webpages       => "$webpages/logreport/html",
		publish        => "$publish/htmlpkg",
		docroot        => "/logreport/html",
		templates      => "html",
		stylesheet     => "/logreport/html/oodoc.css",
	  },
	  {	export       => 'website',
		serializer   => 'json',
		markup       => 'html',
		publish      => "$publish/doctree",
		include_manuals => undef,
	  },
	],
);

my %prereq  = (
	'Test::More'              => '0.86',
	'Sys::Syslog'             => '0.27',
	'Encode'                  => '2.00',
	'Scalar::Util'            => 0,
	'Devel::GlobalDestruction'=> '0.09',
	'Log::Report::Optional'   => '1.07',
	'String::Print'           => '0.91',
);

eval "require Log::Report::Template";
$@ or $prereq{'Log::Report::Template'} = 1.02;

# Upgrade L::R::Lexicon if installed
eval "require Log::Report::Extract";
#warn $@;
unless($@)
{   my $v = $Log::Report::Extract::VERSION || '1.00';
    if($v < 1.00) { warn <<'__CHANGES_100'; sleep 10 }
***************************************************************
WARNING: with Log::Report 1.00, the distribution got spit into
   four separate components.  If you use *translations*, then
   you have to upgrade Log::Report::Lexicon as well.  You may 
   need to add dependencies to that module as well.
***************************************************************
__CHANGES_100
}

#use Data::Dumper;
#warn Dumper \%prereq;

WriteMakefile
	NAME      => 'Log::Report',
	VERSION   => $version,
	PREREQ_PM => \%prereq,

	AUTHOR    => 'Mark Overmeer <markov@cpan.org>',
	ABSTRACT  => 'report a problem, pluggable handlers and language support',
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
					'OODoc' => '3.04',
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
#	../Log-Report-Lexicon/bin/xgettext-perl --mode=VERBOSE -p lib/Log/Report/messages lib
