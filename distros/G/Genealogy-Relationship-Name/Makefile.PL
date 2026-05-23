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
	NAME		=> 'Genealogy::Relationship::Name',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/Genealogy/Relationship/Name.pm',
	ABSTRACT_FROM	=> 'lib/Genealogy/Relationship/Name.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	EXE_FILES => [],
	PL_FILES	=> {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, PREREQ_PM => {
		'autodie' => 0,
		'Carp' => 0,
		'IPC::System::Simple' => 0,
		'Object::Configure' => 0,
		'Params::Get' => 0,
		'Params::Validate::Strict' => 0.31,
		'Readonly::Values::Months' => 0,
		'Readonly' => 0,
	# }, RECOMMENDED => {
		# 'Net::DNS' => 0,
		# 'LWP::UserAgent' => 0,
		# 'HTML::LinkExtor' => 0
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Returns' => 0,
		'Test::Which' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'Genealogy-Relationship-Name-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Genealogy::Relationship::Name',
			repository => {
				repository => 'https://github.com/nigelhorne/Genealogy-Relationship-Name',
				type => 'git',
				url => 'git://github.com/nigelhorne/Genealogy-Relationship-Name.git',
				web => 'https://github.com/nigelhorne/Genealogy-Relationship-Name',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy-Relationship-Name',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy-Relationship-Name',
				# web => 'https://github.com/nigelhorne/Genealogy-Relationship-Name/issues',
				# url => 'https://github.com/nigelhorne/Genealogy-Relationship-Name/issues',
				mailto => 'bug-Genealogy-Relationship-Name@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.010'
);
