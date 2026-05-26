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
	ABSTRACT_FROM	=> 'lib/Genealogy/Military/Branch.pm',
	AUTHOR => 'Nigel Horne <njh@nigelhorne.com>',
	NAME => 'Genealogy::Military::Branch',
	VERSION_FROM => 'lib/Genealogy/Military/Branch.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, PREREQ_PM => {
		'strict'                  => 0,
		'warnings'                => 0,
		'Carp'                    => 0,
		'I18N::LangTags::Detect'  => 0,
		'Object::Configure' => 0.19,
		'Params::Get'             => 0.13,
		'Params::Validate::Strict' => 0.31,
		'Readonly'                => 0,
		'Return::Set'             => 0,
	}, TEST_REQUIRES => {
		'Test::DescribeMe'   => 0,
		'Test::Most'         => 0,
		'Test::Mockingbird'  => 0.09,
	}, dist => $dist,
	clean => { FILES => 'Genealogy-Military-Branch-*' },	# Clean up distribution files
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Genealogy::Military::Branch',
			repository => {
				type => 'git',
				url  => 'git://github.com/nigelhorne/Genealogy-Military-Branch.git',
				web  => 'https://github.com/nigelhorne/Genealogy-Military-Branch',
			}, bugtracker => {
				mailto => 'bug-Genealogy-Military-Branch@rt.cpan.org',
				url    => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy-Military-Branch',
				web    => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy-Military-Branch',
			}
		}
	},
	MIN_PERL_VERSION => '5.014'
);
