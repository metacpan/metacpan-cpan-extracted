use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f', # Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME         => 'Genealogy::Obituary::Parser',
	ABSTRACT_FROM	=> 'lib/Genealogy/Obituary/Parser.pm',
	VERSION_FROM => 'lib/Genealogy/Obituary/Parser.pm',
	AUTHOR	=> 'Nigel Horne <njh@nigelhorne.com>', # Author information
	LICENSE      => 'GPL',
	PREREQ_PM    => {
		'Carp' => 0,
		'DateTime::Format::Text' => 0,
		'JSON::MaybeXS' => 0,
		'Params::Get' => 0.13,
		'Params::Validate::Strict' => 0.10,
		'Return::Set' => 0.03
	}, TEST_REQUIRES => {
		'Data::Random' => 0,
		'File::Glob' => 0,
		'File::Slurp' => 0,
		'File::stat' => 0,
		'IPC::System::Simple' => 0,
		'POSIX' => 0,
		'Readonly' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Returns' => 0,
	}, dist => $dist,
	clean	 => {
		FILES => 'Genealogy-Obituary-Parser-*',
	},
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Genealogy::Obituary::Parser',
			repository => {
				repository => 'https://github.com/nigelhorne/Genealogy-Obituary-Parser',
				type => 'git',
				url => 'git://github.com/nigelhorne/Genealogy-Obituary-Parser.git',
				web => 'https://github.com/nigelhorne/Genealogy-Obituary-Parser',
				# license    => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-Genealogy-Obituary-Parser@rt.cpan.org',
				url => 'https://github.com/nigelhorne/Genealogy-Obituary-Parser/issues',
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy-Obituary-Parser',
				web => 'https://github.com/nigelhorne/Genealogy-Obituary-Parser/issues'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
