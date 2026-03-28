use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		=> 'Email::Abuse::Investigator',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/Email/Abuse/Investigator.pm',
	ABSTRACT_FROM	=> 'lib/Email/Abuse/Investigator.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	EXE_FILES => ['bin/abuse_check', 'bin/submit_abuse_report'],
	PL_FILES	=> {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, PREREQ_PM => {
		'IO::Socket::INET' => 0,
		'MIME::QuotedPrint' => 0,
		'MIME::Base64' => 0,
		'Object::Configure' => 0,
		'Params::Get' => 0,
		'Params::Validate::Strict' => 0,
		'Params::Validate::Strict' => 0,
		'Readonly::Values::Months' => 0,
		'Socket' => 0,
	# }, RECOMMENDED => {
		# 'Net::DNS' => 0,
		# 'LWP::UserAgent' => 0,
		# 'HTML::LinkExtor' => 0
	}, TEST_REQUIRES => {
		'FindBin' => 0,
		'MIME::Base64' => 0,
		'MIME::QuotedPrint' => 0,
		'POSIX' => 0,
		'Scalar::Util' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'Email-Abuse-Investigator-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Email::Abuse::Investigator',
			repository => {
				repository => 'https://github.com/nigelhorne/Email-Abuse-Investigator',
				type => 'git',
				url => 'git://github.com/nigelhorne/Email-Abuse-Investigator.git',
				web => 'https://github.com/nigelhorne/Email-Abuse-Investigator',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Email-Abuse-Investigator',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Email-Abuse-Investigator',
				# web => 'https://github.com/nigelhorne/Email-Abuse-Investigator/issues',
				# url => 'https://github.com/nigelhorne/Email-Abuse-Investigator/issues',
				mailto => 'bug-Email-Abuse-Investigator@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.010'
);
