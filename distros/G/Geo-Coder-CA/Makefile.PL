use strict;
use warnings;
use ExtUtils::MakeMaker;
use Getopt::Long;	# Technique inspired by IO::Lambda
use IO::Socket::INET;

my $online_tests;

if($ENV{RELEASE_TESTING}) {
	$online_tests = are_online();
} elsif($ENV{AUTOMATED_TESTING} || $ENV{NO_NETWORK_TESTING}) {
	$online_tests = 0;
} else {
	Getopt::Long::GetOptions('online-tests!' => \$online_tests);

	if(!defined($online_tests)) {
		$online_tests = are_online();
	}
}

if($online_tests) {
	open(my $enabled, '>', 't/online.enabled') || die "Can't touch t/online.enabled $!";
	close($enabled) || die "Can't touch t/online.enabled $!";
} else {
	unlink('t/online.enabled');
}

WriteMakefile(
    NAME		=> 'Geo::Coder::CA',
    AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM	=> 'lib/Geo/Coder/CA.pm',
    ABSTRACT_FROM       => 'lib/Geo/Coder/CA.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
    BUILD_REQUIRES => {
	'Test::Most' => 0,
	'Test::Number::Delta' => 0,
    },
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
		PeerAddr => 'geocode.ca:443',
		Timeout => 10
	);
	if($s) {
		print <<EOF;

You appear to be directly connected to the Internet.  I have some tests
that try to query geocode.ca.

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
