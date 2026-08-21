use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		=> 'Lingua::Text',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/Lingua/Text.pm',
	ABSTRACT_FROM	 => 'lib/Lingua/Text.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'gpl_2')
	  : ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES	=> {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, PREREQ_PM => {
		'Carp' => 0,
		'HTML::Entities' => 0,
		'I18N::LangTags::Detect' => 0,
		'Object::Configure' => 0,
		'Params::Get' => 0,
		'Readonly' => 0,
		'Scalar::Util' => 0,
		'Sub::Private' => 0,
	}, TEST_REQUIRES => {
		'IPC::System::Simple' => 0,
		'Test::Carp' => 0,
		'Test::DescribeMe' => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Mockingbird' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::NoWarnings' => 0,
		'Test::Returns' => 0
	}, dist => $dist,
	clean		=> { FILES => 'Lingua-Text-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Lingua-Text.git',
				web => 'https://github.com/nigelhorne/Lingua-Text',
				repository => 'https://github.com/nigelhorne/Lingua-Text',
			}, bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Lingua-Text',
				web => 'https://github.com/nigelhorne/Lingua-Text/issues',
				url => 'https://github.com/nigelhorne/Lingua-Text/issues',
				mailto => 'bug-Lingua-Text@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.010'	# use autodie and // (defined-or) require 5.010
);
