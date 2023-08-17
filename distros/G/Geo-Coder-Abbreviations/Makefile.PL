use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use Getopt::Long;	# Technique inspired by IO::Lambda
use IO::Socket::INET;

my $online_tests;

if($ENV{'AUTHOR_TESTING'}) {
	$online_tests = online_tests();
} else {
	Getopt::Long::GetOptions('online-tests!' => \$online_tests);

	if(!defined($online_tests)) {
		$online_tests = online_tests();
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
}

WriteMakefile(
	NAME	=> 'Geo::Coder::Abbreviations',
	AUTHOR	=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM => 'lib/Geo/Coder/Abbreviations.pm',
	ABSTRACT_FROM => 'lib/Geo/Coder/Abbreviations.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	PL_FILES => {},
	BUILD_REQUIRES => {
	}, TEST_REQUIRES => {
		'Test::Most' => 0,
		'Test::NoWarnings' => 0,
		# 'Test::Kwalitee' => 0,
	}, PREREQ_PM => {
		'JSON::MaybeXS' => 0,
		'LWP::Simple::WithCache' => 0,
		'LWP::Protocol::https' => 0,
	},
	dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'Geo-Coder-Abbreviations-*' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Geo-Coder-Abbreviations.git',
				web => 'https://github.com/nigelhorne/Geo-Coder-Abbreviations',
				repository => 'https://github.com/nigelhorne/Geo-Coder-Abbreviations',
			}, bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-Abbreviations',
				web => 'https://github.com/nigelhorne/Geo-Coder-Abbreviations/issues',
				url => 'https://github.com/nigelhorne/Geo-Coder-Abbreviations/issues',
				mailto => 'bug-Geo-Coder-Abbreviations@rt.cpan.org'
			},
		},
	},
	MIN_PERL_VERSION => '5.6.2'	# Probably would work, but never tested on earlier versions than this
);

sub online_tests
{
	return 0 if($ENV{'NO_NETWORK_TESTING'} || $ENV{'TRAVIS_PERL_VERSION'});
	return 0 if($ENV{'AUTOMATED_TESTING'});
	return 0 if(!-t STDIN);

	my $s = IO::Socket::INET->new(
		PeerAddr => 'raw.githubusercontent.com:443',
		Timeout => 5
	);
	if($s) {
		if($ENV{'PERL_MM_USE_DEFAULT'}) {
			close($s);
			return 1;
		}
		print <<EOF;

You appear to be directly connected to the Internet.  I have some tests
that download the data needed to run these tests.

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
