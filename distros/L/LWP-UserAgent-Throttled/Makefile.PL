use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

if(defined($ENV{'GITHUB_ACTION'}) || defined($ENV{'CIRCLECI'}) || defined($ENV{'TRAVIS_PERL_VERSION'}) || defined($ENV{'APPVEYOR'})) {
	# Prevent downloading and installing stuff
	warn 'AUTOMATED_TESTING added for you' if(!defined($ENV{'AUTOMATED_TESTING'}));
	$ENV{'AUTOMATED_TESTING'} = 1;
	$ENV{'NO_NETWORK_TESTING'} = 1;
}

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME => 'LWP::UserAgent::Throttled',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/LWP/UserAgent/Throttled.pm',
	ABSTRACT_FROM => 'lib/LWP/UserAgent/Throttled.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	PL_FILES	=> {},
	TEST_REQUIRES => {
		'LWP::Protocol::https' => 0,
		'Test::DescribeMe' => 0,
		'Test::Exception' => 0.42,	# http://www.cpantesters.org/cpan/report/91a6ac80-6bf9-1014-b7eb-bb2be30b7e63
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::NoWarnings' => 0,
		'Test::RequiresInternet' => 0,
		'Test::Timer' => 2.01,
		# 'Test::Kwalitee' => 0,
	},
	BUILD_REQUIRES => {
		'IO::Socket::INET' => 0,
	},
	PREREQ_PM => {
		'LWP' => 0,
		'LWP::UserAgent' => 0,
		'Time::HiRes' => 0,
		'URI' => 0
	}, dist => $dist,
	clean		=> { FILES => 'LWP-UserAgent-Throttled-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE	=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/LWP-UserAgent-Throttled.git',
				web => 'https://github.com/nigelhorne/LWP-UserAgent::Throttled',
			},
			bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=LWP-UserAgent::Throttled',
				web => 'https://github.com/nigelhorne/LWP-UserAgent-Throttled/issues',
				url => 'https://github.com/nigelhorne/LWP-UserAgent-Throttled/issues',
				mailto => 'bug-LWP-UserAgent::Throttled@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION => '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
