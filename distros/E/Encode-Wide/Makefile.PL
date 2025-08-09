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
	NAME	=> 'Encode::Wide',
	AUTHOR	=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM => 'lib/Encode/Wide.pm',
	ABSTRACT_FROM => 'lib/Encode/Wide.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, PREREQ_PM    => {
		'Exporter'       => 0,
		'HTML::Entities' => 0,
		'Params::Get' => 0.13,
		'Term::ANSIColor' => 0,
	},  TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Returns' => 0,
	}, dist => $dist,
	clean => { FILES => 'Encode-Wide-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Encode::Wide',
			repository => {
				repository => 'https://github.com/nigelhorne/Encode-Wide',
				type => 'git',
				url => 'git://github.com/nigelhorne/Encode-Wide.git',
				web => 'https://github.com/nigelhorne/Encode-Wide',
				# license    => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-Encode-Wide@rt.cpan.org',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Encode-Wide',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Encode-Wide',
				# url => 'https://github.com/nigelhorne/Encode-Wide/issues',
				# web => 'https://github.com/nigelhorne/Encode-Wide/issues'
			}
		},
	},
	MIN_PERL_VERSION => '5.10.0',
);
