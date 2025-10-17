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
	NAME		=> 'HTML::Genealogy::Map',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/HTML/Genealogy/Map.pm',
	ABSTRACT_FROM	=> 'lib/HTML/Genealogy/Map.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES	=> {},
	EXE_FILES => ['bin/ged2map'],
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, PREREQ_PM => {
		'autodie' => 0,
		'Date::Cmp' => 0,
		'HTML::GoogleMaps::V3' => 0,
		'HTML::OSM' => 0,
		'Gedcom' => 0,
		'Object::Configure' => 0.15,
		'Params::Get' => 0.13,
		'Params::Validate::Strict' => 0.16,
	}, TEST_REQUIRES => {
		'Class::Simple' => 0,
		'Data::Random' => 0,
		'IPC::System::Simple' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::NoWarnings' => 0,
		'Test::Returns' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'HTML-Genealogy-Map-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/HTML::Genealogy::Map',
			repository => {
				repository => 'https://github.com/nigelhorne/HTML-Genealogy-Map',
				type => 'git',
				url => 'git://github.com/nigelhorne/HTML-Genealogy-Map.git',
				web => 'https://github.com/nigelhorne/HTML-Genealogy-Map',
				# license    => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-HTML-Genealogy-Map@rt.cpan.org',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Genealogy-Map',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Genealogy-Map',
				# url => 'https://github.com/nigelhorne/HTML-Genealogy-Map/issues',
				# web => 'https://github.com/nigelhorne/HTML-Genealogy-Map/issues'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
