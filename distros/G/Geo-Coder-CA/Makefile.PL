use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use Getopt::Long;	# Technique inspired by IO::Lambda
use IO::Socket::INET;

my $online_tests;

if($ENV{AUTHOR_TESTING}) {
	$online_tests = are_online();
} else {
	Getopt::Long::GetOptions('online-tests!' => \$online_tests);

	if(!defined($online_tests)) {
		$online_tests = are_online();
	}
	if(!$online_tests) {
		print "On-line tests have been disabled\n";
		$online_tests = 0;
	}
}


my $test_requires = {
	'autodie' => 0,
	'IPC::System::Simple' => 0,	# http://www.cpantesters.org/cpan/report/0b994acc-7a03-11e8-a944-5f7713bf8fb6
	'Test::Most' => 0,
	'Test::NoWarnings' => 0,
	'Test::Number::Delta' => 0,
	'Test::Carp' => 0,
	'Test::Script' => 1.12,
	'WWW::RT::CPAN' => 0
};

if($online_tests) {
	open(my $enabled, '>', 't/online.enabled') || die "Can't touch t/online.enabled $!";
	close($enabled) || die "Can't touch t/online.enabled $!";
	$test_requires->{'Test::LWP::UserAgent'} = 0;
} else {
	unlink('t/online.enabled');
}

WriteMakefile(
	NAME		=> 'Geo::Coder::CA',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/Geo/Coder/CA.pm',
	ABSTRACT_FROM	=> 'lib/Geo/Coder/CA.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	PL_FILES	=> {},
	TEST_REQUIRES => $test_requires,
	PREREQ_PM => {
		'Encode' => 0,
		'JSON::MaybeXS' => 0,
		'HTTP::Request' => 0,
		'LWP::UserAgent' => 0,
		'LWP::Protocol::https' => 0,
		'URI' => 0,
	},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean		=> { FILES => 'Geo-Coder-CA-*' },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Geo-Coder-CA.git',
				web => 'https://github.com/nigelhorne/Geo-Coder-CA',
				repository => 'https://github.com/nigelhorne/Geo-Coder-CA',
			}, bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-CA',
				web => 'https://github.com/nigelhorne/Geo-Coder-CA/issues',
				url => 'https://github.com/nigelhorne/Geo-Coder-CA/issues',
				mailto => 'bug-Geo-Coder-CA@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);

sub are_online
{
	return 0 if($ENV{'NO_NETWORK_TESTING'} || $ENV{'TRAVIS_PERL_VERSION'});
	return 0 if(!-t STDIN);

	my $s = IO::Socket::INET->new(
		PeerAddr => 'geocoder.ca:443',
		Timeout => 10
	);
	if($s) {
		if($ENV{'PERL_MM_USE_DEFAULT'} || $ENV{'AUTOMATED_TESTING'}) {
			close($s);
			return 1;
		}

		print <<EOF;

You appear to be directly connected to the Internet.  I have some tests
that try to query geocoder.ca.

EOF
		close($s);

		# Timeout inspired by Mail::IMAPClient
		my $rc;
		eval {
			local $SIG{ALRM} = sub { die 'alarm' };
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
