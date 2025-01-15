#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use Getopt::Long;	# Technique inspired by IO::Lambda
use IO::Socket::INET;

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
} else {
	unlink('t/online.enabled');
	# Allow cheating for some tests
	unless(defined($ENV{'GITHUB_ACTION'}) || defined($ENV{'CIRCLECI'}) || defined($ENV{'TRAVIS_PERL_VERSION'}) || defined($ENV{'APPVEYOR'})) {
		print STDERR "NA: Genealogy::FindaGrave needs a permanent connexion to the Internet\n";
		exit(0);
	}
}

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
    NAME		=> 'Genealogy::FindaGrave',
    AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM	=> 'lib/Genealogy/FindaGrave.pm',
    ABSTRACT_FROM       => 'lib/Genealogy/FindaGrave.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
    TEST_REQUIRES => {
	'Test::DescribeMe' => 0,
	'Test::Most' => 0,
	'Test::Needs' => 0,
	'Test::NoWarnings' => 0,
	'Test::URI' => 0,
	# 'Test::Kwalitee' => 0,
    }, PREREQ_PM => {
    	'Carp' => 0,
	'LWP::UserAgent' => 0,
	'HTML::SimpleLinkExtor' => 0,
	'LWP::Protocol::https' => 0,
	'Scalar::Util' => 0
    }, dist => $dist,
    clean		=> { FILES => 'Genealogy-FindaGrave-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/Genealogy-FindaGrave.git',
			web => 'https://github.com/nigelhorne/Genealogy-FindaGrave',
    		},
		bugtracker => {
			# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy-FindaGrave',
			# mailto => 'bug-Genealogy-FindaGrave@rt.cpan.org'
			web => 'https://github.com/nigelhorne/Genealogy-FindaGrave/issues',
			url => 'https://github.com/nigelhorne/Genealogy-FindaGrave/issues',
		}
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);

sub are_online
{
	return 0 if($ENV{'NO_NETWORK_TESTING'} || $ENV{'CIRCLECI'} || $ENV{'TRAVIS_PERL_VERSION'} || $ENV{'AUTOMATED_TESTING'} || $ENV{'NONINTERACTIVE_TESTING'} || (!-t STDIN));

	my $host = 'www.findagrave.com:80';

	if($ENV{'http_proxy'} && ($ENV{'http_proxy'} =~ /^.+\/\/(\w+:\d+)$/)) {
		$host = "$1:3128";
	} elsif($ENV{'HTTP_PROXY'} && ($ENV{'HTTP_PROXY'} =~ /^.+\/\/(\w+:\d+)$/)) {
		$host = "$1:3128";
	}
	if(my $s = IO::Socket::INET->new(
		# PeerAddr => 'www.ripe.net:43',
		# PeerAddr => 'whois.apnic.net:43',
		PeerAddr => $host,
		Timeout => 5
	)) {
		print <<EOF;

You appear to be directly connected to the Internet.  I have some tests
that connect to www.findagrave.com.

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
