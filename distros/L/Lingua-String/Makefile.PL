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
	NAME		=> 'Lingua::String',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/Lingua/String.pm',
	ABSTRACT_FROM	 => 'lib/Lingua/String.pm',
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
	clean		=> { FILES => 'Lingua-String-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Lingua-String.git',
				web => 'https://github.com/nigelhorne/Lingua-String',
				repository => 'https://github.com/nigelhorne/Lingua-String',
			}, bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Lingua-String',
				web => 'https://github.com/nigelhorne/Lingua-String/issues',
				url => 'https://github.com/nigelhorne/Lingua-String/issues',
				mailto => 'bug-Lingua-String@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
