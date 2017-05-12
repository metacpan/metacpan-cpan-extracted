use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'File::Find::Rule::Digest',
    'VERSION_FROM' => 'lib/File/Find/Rule/Digest.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	File::Find::Rule => 0,
	Digest => 0,
    },
);
