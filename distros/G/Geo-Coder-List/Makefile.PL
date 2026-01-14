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
	'Test::Deep' => 0,
	'Test::DescribeMe' => 0,
	'Test::Mockingbird' => 0,
	'Test::MockModule' => 0,
	'Test::MockObject' => 0,
	'Test::Most' => 0,
	'Test::Needs' => 0,
	'Test::NoWarnings' => 0,
	'Test::Number::Delta' => 0,	# Always needed since used in free.t
	'Test::RequiresInternet' => 0,
	'Test::Without::Module' => 0,
};

if($online_tests) {
	open(my $enabled, '>', 't/online.enabled') || die "Can't touch t/online.enabled $!";
	close($enabled) || die "Can't touch t/online.enabled $!";
	# $test_requires->{'Geo::Coder::Google::V3'} = 0.10;
	$test_requires->{'Geo::Coder::OSM'} = 0;
	$test_requires->{'Geo::Coder::CA'} = 0;
	$test_requires->{'Geo::Coder::DataScienceToolkit'} = 0;
	$test_requires->{'Geo::Coder::OpenCage'} = 0;
	$test_requires->{'Geo::Coder::GeocodeFarm'} = 0;
	$test_requires->{'Geo::Coder::Ovi'} = 0;
	$test_requires->{'Geo::Coder::Postcodes'} = 0;
	# $test_requires->{'Geo::Coder::XYZ'} = 0.06;
	$test_requires->{'Test::LWP::UserAgent'} = 0;
	$test_requires->{'Test::Carp'} = 0;
	$test_requires->{'LWP::UserAgent::Throttled'} = 0.04;
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

WriteMakefile(
	NAME		=> 'Geo::Coder::List',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/Geo/Coder/List.pm',
	ABSTRACT_FROM	=> 'lib/Geo/Coder/List.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
    TEST_REQUIRES => $test_requires,
    PREREQ_PM => {
	'Carp' => 0,
	'HTML::Entities' => 0,
	'LWP::Protocol::https' => 0,
	'Object::Configure' => 0.13,
	'Params::Get' => 0.04,
	'Scalar::Util' => 0,
	'Time::HiRes' => 0
    }, dist => $dist,
    clean		=> { FILES => 'Geo-Coder-List-*' },
    META_MERGE		=> {
	'meta-spec' => { version => 2 },
	resources => {
		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/Geo-Coder-List.git',
			web => 'https://github.com/nigelhorne/Geo-Coder-List',
		}, bugtracker => {
			web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-List',
			mailto => 'bug-Geo-Coder-List@rt.cpan.org'
		}
	},
    },
    MIN_PERL_VERSION	=> '5.10.1'
);

sub are_online
{
	return 0 if($ENV{'NO_NETWORK_TESTING'} || $ENV{'CIRCLECI'} || $ENV{'TRAVIS_PERL_VERSION'} || $ENV{'AUTOMATED_TESTING'} || $ENV{'NONINTERACTIVE_TESTING'} || (!-t STDIN));

	if(my $s = IO::Socket::INET->new(
		PeerAddr => 'openstreetmap.org:443',
		Timeout => 10
	))  {
		if($ENV{'PERL_MM_USE_DEFAULT'}) {
			close($s);
			return 0;
		}

		print <<EOF;

You appear to be directly connected to the Internet.  I have some tests
that try to query various geocode services.

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
