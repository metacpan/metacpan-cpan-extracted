use strict;
use warnings;
use ExtUtils::MakeMaker;
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
	# The tests assert the rule's own answer, so they need it even though the
	# module does not: Geo-Location-Predicate is a recommendation for runtime
	# (META_MERGE below), and t/reference.t skips the comparisons it cannot
	# make when it is absent.
	'Geo::Location::Predicate' => 0,
	'Test::Compile' => 0,
	'Test::DescribeMe' => 0,
	'Test::Most' => 0,
	'Test::Needs' => 0,
	'Test::NoWarnings' => 0,
};

if($online_tests) {
	open(my $enabled, '>', 't/online.enabled') || die "Can't touch t/online.enabled $!";
	close($enabled) || die "Can't touch t/online.enabled $!";
	$test_requires->{'Test::LWP::UserAgent'} = 0;
	$test_requires->{'Test::Number::Delta'} = 0;
	$test_requires->{'Test::Carp'} = 0;
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
	NAME		=> 'Geo::Coder::Postcodes',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/Geo/Coder/Postcodes.pm',
	ABSTRACT_FROM	=> 'lib/Geo/Coder/Postcodes.pm',
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
		'Params::Get' => 0.13,
		'Object::Configure' => 0.14,
		'URI' => 0,
	},
	dist => $dist,
	clean		=> { FILES => 'Geo-Coder-Postcodes-*' },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		# A real optional dependency: an installer fetches it by default, and an
		# install that leaves it out still gets the reference refusal.  The code
		# looks for it the first time it is needed, not when the module loads.
		prereqs => {
			runtime => {
				recommends => {
					'Geo::Location::Predicate' => '0.01',
				},
			},
		},
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Geo-Coder-Postcodes.git',
				web => 'https://github.com/nigelhorne/Geo-Coder-Postcodes',
				repository => 'https://github.com/nigelhorne/Geo-Coder-Postcodes',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-Postcodes',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-Postcodes',
				# web => 'https://github.com/nigelhorne/Geo-Coder-Postcodes/issues',
				# url => 'https://github.com/nigelhorne/Geo-Coder-Postcodes/issues',
				mailto => 'bug-Geo-Coder-Postcodes@rt.cpan.org'
			}
		}
	},
	MIN_PERL_VERSION => '5.6.2'	# Probably would work, but never tested on earlier versions than this
);

sub are_online
{
	return 0 if($ENV{'NO_NETWORK_TESTING'} || $ENV{'CIRCLECI'} || $ENV{'TRAVIS_PERL_VERSION'} || $ENV{'AUTOMATED_TESTING'} || $ENV{'NONINTERACTIVE_TESTING'} || (!-t STDIN));

	if(my $s = IO::Socket::INET->new(
		PeerAddr => 'postcodes.io:443',
		Timeout => 10
	)) {
		if($ENV{'PERL_MM_USE_DEFAULT'}) {
			close($s);
			return 1;
		}
		print <<EOF;

You appear to be directly connected to the Internet.  I have some tests
that try to query postcodes.io.

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
