use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use File::Spec;

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
    NAME		=> 'Log::Log4perl::Layout::Syslog',
    AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM	=> 'lib/Log/Log4perl/Layout/Syslog.pm',
    ABSTRACT_FROM       => 'lib/Log/Log4perl/Layout/Syslog.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
    TEST_REQUIRES => {
	'Test::DescribeMe' => 0,
	'Test::Most' => 0,
	'Test::Needs' => 0,
	'Test::NoWarnings' => 0,
    },
    PREREQ_PM => {
	# 'Log::Log4perl::Layout' => 0,
	# 'Net::Address::IP::Local' => 0,
	'Scalar::Util' => 0
    }, dist => $dist,
	clean	=> { FILES => 'Log-Log4perl-Layout-Syslog-*' },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				repository => 'https://github.com/nigelhorne/Log-Log4perl-Layout-Syslog',
				type => 'git',
				url => 'git://github.com/nigelhorne/Log-Log4perl-Layout-Syslog.git',
				web => 'https://github.com/nigelhorne/Log-Log4perl-Layout-Syslog'
			}, bugtracker => {
				mailto => 'bug-Log-Log4perl-Layout-Syslog@rt.cpan.org',
				url => 'https://github.com/nigelhorne/Log-Log4perl-Layout-Syslog/issues',
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Log4perl-Layout-Syslog',
				web => 'https://github.com/nigelhorne/Log-Log4perl-Layout-Syslog/issues'
			}
		},
	},
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
