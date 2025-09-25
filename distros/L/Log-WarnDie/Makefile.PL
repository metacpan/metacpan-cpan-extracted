#!/usr/bin/env perl

require 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use File::Spec 3.4;
use IO::Socket::INET;
use Getopt::Long;	# Technique inspired by IO::Lambda
eval 'use Devel::Required';

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

my $test_requires = {
	'Log::Dispatch::Null' => 0,
	'Test::DescribeMe' => 0,
	'Test::Most' => 0,
	'Test::Needs' => 0,
	'Test::TempDir::Tiny' => 0,
	'autodie' => 0,
	'IPC::System::Simple' => 0,
	'Test::File::Contents' => 0,
	'File::Spec' => 3.4,
};

if($online_tests) {
	open(my $enabled, '>', 't/online.enabled') || die "Can't touch t/online.enabled $!";
	close($enabled) || die "Can't touch t/online.enabled $!";

	$test_requires->{'Net::SFTP::Foreign'} = 0;
} else {
	unlink('t/online.enabled');
}

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile (
	NAME		=> "Log::WarnDie",
	# AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/Log/WarnDie.pm',
	ABSTRACT_FROM   => 'lib/Log/WarnDie.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
		($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	PREREQ_PM	=> {
		'Scalar::Util' => 1.08,
	},
	TEST_REQUIRES => $test_requires,
	dist => $dist,
	clean		=> { FILES => 'Log::WarnDie-*' },
	META_MERGE	=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Log::WarnDie.git',
				web => 'https://github.com/nigelhorne/Log::WarnDie',
				repository => 'https://github.com/nigelhorne/Log-WarnDie',
			},
			bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Log::WarnDie',
				web => 'https://github.com/nigelhorne/Log-WarnDie',
				mailto => 'bug-Log::WarnDie@rt.cpan.org'
			}
		}
	},
	MIN_PERL_VERSION	=> '5.6.2'
);

sub are_online
{
	return 0 if($ENV{'NO_NETWORK_TESTING'} || $ENV{'CIRCLECI'} || $ENV{'TRAVIS_PERL_VERSION'}) || $ENV{'AUTOMATED_TESTING'} || (!-t STDIN);

	if(my $s = IO::Socket::INET->new(
		# PeerAddr => 'www.ripe.net:43',
		PeerAddr => 'test.rebex.net:22',
		Timeout => 5
	)) {
		print <<EOF;

You appear to be directly connected to the Internet.  I have a regression test
that tries to query an SFTP server.

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
