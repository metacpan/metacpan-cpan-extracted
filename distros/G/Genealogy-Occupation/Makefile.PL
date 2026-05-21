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
	ABSTRACT_FROM	=> 'lib/Genealogy/Occupation.pm',
	AUTHOR => 'Nigel Horne <njh@nigelhorne.com>',
	NAME => 'Genealogy::Occupation',
	VERSION_FROM => 'lib/Genealogy/Occupation.pm', # finds $VERSION in the module
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, PREREQ_PM => {
		'strict' => 0,
		'warnings' => 0,
		'Carp' => 0,
		'I18N::LangTags::Detect' => 0,
		'Lingua::EN::ABC' => 0,
		'Params::Get' => 0,
		'Params::Validate::Strict' => 0,
		'Readonly' => 0,
		'Return::Set' => 0,
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Mockingbird' => 0.10,
	}, dist => $dist,
	clean => { FILES => 'Genealogy-Occupation-*' },	# Clean up distribution files
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Genealogy::Occupation',
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Genealogy-Occupation.git',
				web => 'https://github.com/nigelhorne/Genealogy-Occupation',
				# license    => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-Genealogy-Occupation@rt.cpan.org',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy-Occupation',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy-Occupation',
			}
		}
	},
	MIN_PERL_VERSION	=> '5.014'
);
