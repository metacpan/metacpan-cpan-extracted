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
	NAME		=> 'Locale::Codes::Country::FR',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/Locale/Codes/Country/FR.pm',
	ABSTRACT_FROM   => 'lib/Locale/Codes/Country/FR.pm',
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
		# 'Test::Kwalitee' => 0,
	},
	PREREQ_PM => {
		'Data::Section::Simple' => 0,
		'Locale::Codes::Country' => 0,
		'Locale::Codes' => 3.59,	# Silence noisy warn messages in perl 5.28
		'Scalar::Util' => 0
	}, dist => $dist,
	clean		=> { FILES => 'Locale-Codes-Country-FR-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Locale-Codes-Country-FR.git',
				web => 'https://github.com/nigelhorne/Locale-Codes-Country-FR',
				repository => 'https://github.com/nigelhorne/Locale-Codes-Country-FR',
			},
			bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Locale-Codes-Country-FR',
				# mailto => 'bug-Locale-Codes-Country-FR@rt.cpan.org'
				web => 'https://github.com/nigelhorne/Locale-Codes-Country-FR/issues',
				url => 'https://github.com/nigelhorne/Locale-Codes-Country-FR/issues',
			}
		},
	},
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
