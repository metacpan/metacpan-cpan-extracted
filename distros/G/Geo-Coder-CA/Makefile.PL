use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use Getopt::Long;	# Technique inspired by IO::Lambda
use IO::Socket::INET;

my $online_tests;

if($ENV{AUTHOR_TESTING}) {
	$online_tests = are_online();
} elsif($ENV{AUTOMATED_TESTING} || $ENV{NO_NETWORK_TESTING} || (!-t STDIN)) {
	$online_tests = 0;
} else {
	Getopt::Long::GetOptions('online-tests!' => \$online_tests);

	if(!defined($online_tests)) {
		if($ENV{AUTHOR_TESTING}) {
			$online_tests = are_online();
		} else {
			$online_tests = 0;
		}
	}
}

my $test_requires = {
	'autodie' => 0,
	'IPC::System::Simple' => 0,	# http://www.cpantesters.org/cpan/report/0b994acc-7a03-11e8-a944-5f7713bf8fb6
	'Test::Most' => 0,
	'Test::NoWarnings' => 0,
	'Test::Number::Delta' => 0,
	'Test::Carp' => 0,
	'Test::Script' => 0,
	'Test::LWP::UserAgent' => 0,
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
		'JSON' => 0,
		'HTTP::Request' => 0,
		'LWP::UserAgent' => 0,
		'LWP::Protocol::https' => 0,
		'URI' => 0,
	},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean		=> { FILES => 'Geo-Coder-CA-*' },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/Geo-Coder-CA.git',
			web => 'https://github.com/nigelhorne/Geo-Coder-CA',
			},
			bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-CA',
				mailto => 'bug-Geo-Coder-CA@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);

sub are_online
{
	my $s = IO::Socket::INET->new(
		PeerAddr => 'geocoder.ca:443',
		Timeout => 10
	);
	if($s) {
		print <<EOF;

You appear to be directly connected to the Internet.  I have some tests
that try to query geocoder.ca.

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
	} else {
		print "On-line tests disabled because I couldn't detect an Internet connexion\n";
		return 0;
	}
}
