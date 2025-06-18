use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Mhouse::Reports',
    VERSION_FROM => 'lib/Mhouse/Reports.pm',
    AUTHOR       => 'Lubell Yamamoto <lubell@cpan.org>',
    ABSTRACT     => 'Reading data from JSON files with business data including LLM-scored company descriptions and generating a basic html report.',
    LICENSE      => 'perl',
	PREREQ_PM => {
		'File::Path' => 0,
		'File::Find' => 0,
		'Cwd'        => 0,
		'File::Spec' => 0,
		'JSON'       => 0,
		'DateTime'   => 0,
	},
);
