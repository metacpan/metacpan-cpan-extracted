#!/usr/bin/env perl
use ExtUtils::MakeMaker;

use 5.016;

my $version = '0.18';

# Use command 'oodist' to produce your whole software release.
my $git      = "https://github.com/markov2/perl5-Math-Formula";
my $publish  = "../public_html/math-formula";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.03,
	first_year    => 2023,
	email         => "markov\@cpan.org",

	include  => [
	],

	use      => [
	],

	parser   => {
		syntax         => 'markov',
		skip_links     => [ 'MF' ],
		pmhead         => undef,
	},

	tests    => {
	},

	raw  => {
		publish        => "$publish/raw",
	},

	release  => {
		publish        => "$publish/source",
	},

	generate => [
	  {	# Add real pod to the releases
		format         => 'pod3',
		podtail        => undef,
	  },
	],
);

my %prereq = (
	'Test::More'    => 0,
	'Log::Report'   => 0,
	'POSIX'         => 0,
	'Scalar::Util'  => 0,
	'File::Spec'    => 0,
	'File::Slurper' => 0,

	'DateTime'           => 0,
	'DateTime::Duration' => 0,
	'DateTime::TimeZone' => 0,
	'DateTime::TimeZone::OffsetOnly' => 0,
	'DateTime::Format::Duration::ISO8601' => 0.006,
);

# Some optional modules.  When installed, they need to have at least
# the minimal version.
eval "require YAML::XS";
unless($@)
{	$prereq{'YAML::XS'} = 0.81;
 	$prereq{'boolean'}  = 0.46;
}

eval "require Config::INI";
unless($@)
{	$prereq{'Config::INI'} = 0.025;
}

eval "require Cpanel::JSON::XS";
unless($@)
{	$prereq{'Cpanel::JSON::XS'} = 4.35;
	$prereq{'File::Slurper'} = 0.012;
}

WriteMakefile
	NAME         => 'Math::Formula',
	VERSION      => $version,
	PREREQ_PM    => \%prereq,
	AUTHOR       => 'Mark Overmeer <markov@cpan.org>',
	ABSTRACT     => 'Expressions on steroids',
	LICENSE      => 'perl_5',

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
					'OODoc' => 3.02,
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
