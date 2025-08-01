#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;	# Technique inspired by IO::Lambda
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use IO::Socket::INET;

# Test for broken smokers that don't set AUTOMATED_TESTING
if(my $reporter = $ENV{'PERL_CPAN_REPORTER_CONFIG'}) {
	if($reporter =~ /smoker/i) {
		warn 'AUTOMATED_TESTING added for you' if(!defined($ENV{'AUTOMATED_TESTING'}));
		$ENV{'AUTOMATED_TESTING'} = 1;
	}
}

if(defined($ENV{'GITHUB_ACTION'}) || defined($ENV{'CIRCLECI'}) || defined($ENV{'TRAVIS_PERL_VERSION'}) || defined($ENV{'APPVEYOR'})) {
	# Prevent downloading and installing stuff
	warn 'AUTOMATED_TESTING added for you' if(!defined($ENV{'AUTOMATED_TESTING'}));
	$ENV{'AUTOMATED_TESTING'} = 1;
	$ENV{'NO_NETWORK_TESTING'} = 1;
}

my $online_tests;

if($ENV{'AUTHOR_TESTING'}) {
	$online_tests = are_online();
} else {
	Getopt::Long::GetOptions('online-tests!' => \$online_tests);

	if(!defined($online_tests)) {
		$online_tests = are_online();
	}
	if(!$online_tests) {
		print "On-line tests have been disabled\n";
	}
}


if($online_tests) {
	open(my $enabled, '>', 't/online.enabled') || die "Can't touch t/online.enabled $!";
	close($enabled) || die "Can't touch t/online.enabled $!";
} elsif(!$ENV{'AUTOMATED_TESTING'}) {
	unlink('t/online.enabled');
	print STDERR "NA: Genealogy::ChroniclingAmerica needs a permanent connexion to the Internet\n";
	exit(0);
}

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
    NAME		=> 'Genealogy::ChroniclingAmerica',
    AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
    VERSION_FROM	=> 'lib/Genealogy/ChroniclingAmerica.pm',
    ABSTRACT_FROM   => 'lib/Genealogy/ChroniclingAmerica.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
    TEST_REQUIRES => {
	'Test::DescribeMe' => 0,
	'Test::HTTPStatus' => 0,
	'Test::MockObject' => 0,
	'Test::Most' => 0,
	'Test::Needs' => 0,
	'Test::NoWarnings' => 0,
	'Test::RequiresInternet' => 0,
	'Test::URI' => 0,
	# 'Test::Kwalitee' => 0,
    }, PREREQ_PM => {
	'Carp' => 0,
	'JSON::MaybeXS' => 0,
	'LWP::Protocol::https' => 0,
	'LWP::UserAgent' => 0,
	'Object::Configure' => 0,
	'Params::Get' => 0,
	'Return::Set' => 0,
	'Scalar::Util' => 0,
	'URI' => 0
    }, dist => $dist,
    clean		=> { FILES => 'Genealogy-ChroniclingAmerica-*' },
    META_MERGE		=> {
	'meta-spec' => { version => 2 },
	resources => {
		repository => {
			repository => 'https://github.com/nigelhorne/Genealogy-ChroniclingAmerica',
			type => 'git',
			url => 'git://github.com/nigelhorne/Genealogy-ChroniclingAmerica.git',
			web => 'https://github.com/nigelhorne/Genealogy-ChroniclingAmerica',
		}, bugtracker => {
			mailto => 'bug-Genealogy-ChroniclingAmerica@rt.cpan.org',
			url => 'https://github.com/nigelhorne/Genealogy-ChroniclingAmerica/issues',
			# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy-ChroniclingAmerica',
			web => 'https://github.com/nigelhorne/Genealogy-ChroniclingAmerica/issues'
		}, homepage => 'https://chroniclingamerica.loc.gov',
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);

sub are_online
{
	return 0 if($ENV{'NO_NETWORK_TESTING'} || $ENV{'CIRCLECI'} || $ENV{'TRAVIS_PERL_VERSION'} || $ENV{'AUTOMATED_TESTING'} || $ENV{'NONINTERACTIVE_TESTING'} || (!-t STDIN));
	my $host = 'chroniclingamerica.loc.gov:443';

	if($ENV{'https_proxy'} && ($ENV{'https_proxy'} =~ /^.+\/\/(\w+:\d+)$/)) {
		$host = "$1:3128";
	} elsif($ENV{'HTTPS_PROXY'} && ($ENV{'HTTPS_PROXY'} =~ /^.+\/\/(\w+:\d+)$/)) {
		$host = "$1:3128";
	}
	if(my $s = IO::Socket::INET->new(
		PeerAddr => $host,
		Timeout => 5
	)) {
		if($ENV{'AUTOMATED_TESTING'}) {
			close($s);
			return 1;
		}
		print <<EOF;

You appear to be directly connected to the Internet.  I have some tests
that connect to chroniclingamerica.loc.gov.

EOF
		close($s);

		# Timeout inspired by Mail::IMAPClient
		my $rc;
		eval {
			local $SIG{ALRM} = sub { die "alarm\n" };
			alarm(60);
			$rc = prompt('Do you want to enable these tests?', 'y') =~ /^y/i ? 1 : 0;
			alarm(0);
		};
		if($@) {
			print "\n";
			return 1;	# The default is 'y'
		}
		return $rc;
	}
	print "On-line tests disabled because I couldn't detect an Internet connexion\n";
	return 0;
}
