use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
    NAME		=> 'File::pfopen',
    AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM	=> 'lib/File/pfopen.pm',
    ABSTRACT_FROM       => 'lib/File/pfopen.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
    TEST_REQUIRES => {
	'Test::DescribeMe' => 0,
	'Test::Most' => 0,
	'Test::TempDir::Tiny' => 0,
	'Test::Needs' => 0,
	'Test::NoWarnings' => 0,
    },
    PREREQ_PM => {
	'File::Spec' => 0,
	'Exporter' => 0,
    }, dist => $dist,
    clean		=> { FILES => 'File-pfopen-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/File-pfopen.git',
			web => 'https://github.com/nigelhorne/File-pfopen',
    		},
		bugtracker => {
			web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=File-pfopen',
			mailto => 'bug-File-pfopen@rt.cpan.org'
		}
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
