use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

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
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES	=> {},
	TEST_REQUIRES => {
		'Test::Carp' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::NoWarnings' => 0
	}, PREREQ_PM => {
		'Carp' => 0,
		'Exporter' => 0,
		'ExtUtils::MakeMaker' => 6.64,	# 6.64 for TEST_REQUIRES
		'HTML::Entities' => 0,
		'Params::Get' => 0,
		'Scalar::Util' => 0
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
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
