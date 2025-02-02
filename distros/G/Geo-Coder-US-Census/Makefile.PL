use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use Getopt::Long;	# Technique inspired by IO::Lambda
use IO::Socket::INET;

my $test_requires = {
	'Test::DescribeMe' => 0,
	'Test::Most' => 0,
	'Test::NoWarnings' => 0,
	'Test::Needs' => 0,
	'Test::Number::Delta' => 0,
	'Test::RequiresInternet' => 0,
	'Test::Carp' => 0,
	'IPC::System::Simple' => 0,
	'Test::LWP::UserAgent' => 0
};

if(are_online()) {
	open(my $enabled, '>', 't/online.enabled') || die "Can't touch t/online.enabled $!";
	close($enabled) || die "Can't touch t/online.enabled $!";
	$test_requires->{'Test::LWP::UserAgent'} = 0;
	$test_requires->{'Test::Script'} = 1.12;
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
	NAME		=> 'Geo::Coder::US::Census',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/Geo/Coder/US/Census.pm',
	ABSTRACT_FROM	   => 'lib/Geo/Coder/US/Census.pm',
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
		'Geo::StreetAddress::US' => 0,
		'Net::SSLeay' => 1.81,
	}, dist => $dist,
	clean		=> { FILES => 'Geo-Coder-US-Census-*' },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/Geo-Coder-US-Census.git',
			web => 'https://github.com/nigelhorne/Geo-Coder-US-Census',
			},
			bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-US-Census',
				mailto => 'bug-Geo-Coder-US-Census@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);

sub are_online
{
	return 0 if($ENV{'NO_NETWORK_TESTING'} || $ENV{'CIRCLECI'} || $ENV{'TRAVIS_PERL_VERSION'} || $ENV{'AUTOMATED_TESTING'} || $ENV{'NONINTERACTIVE_TESTING'} || (!-t STDIN));

	if(my $s = IO::Socket::INET->new(
		PeerAddr => 'geocoding.geo.census.gov:443',
		Timeout => 10
	)) {
		if($ENV{'PERL_MM_USE_DEFAULT'} || $ENV{'AUTOMATED_TESTING'}) {
			close($s);
			return 1;
		}
		print <<EOF;

You appear to be directly connected to the Internet.  I have some tests
that try to query geocoding.geo.census.gov.

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
