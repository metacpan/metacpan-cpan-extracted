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
    NAME                => 'Locale::AU',
    AUTHOR              => q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM        => 'lib/Locale/AU.pm',
    ABSTRACT_FROM       => 'lib/Locale/AU.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES => {},
    BUILD_REQUIRES => {
    }, PREREQ_PM => {
	'Data::Section::Simple' => 0,
    }, TEST_REQUIRES => {
	# 'Test::Kwalitee' => 0,
	'Test::DescribeMe' => 0,
	'Test::Most' => 0,
	'Test::Needs' => 0,
	'Test::Needs' => 0,
	'Test::NoWarnings' => 0,
    },
    clean               => { FILES => 'Locale-AU-*' },
    dist => $dist,
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/Locale-AU.git',
			web => 'https://github.com/nigelhorne/Locale-AU-Info',
    		},
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
