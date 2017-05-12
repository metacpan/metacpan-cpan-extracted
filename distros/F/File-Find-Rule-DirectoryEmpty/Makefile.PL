use ExtUtils::MakeMaker;
WriteMakefile(
	VERSION_FROM =>'lib/File/Find/Rule/DirectoryEmpty.pm',
	NAME => 'File::Find::Rule::DirectoryEmpty',
	PREREQ_PM => {
		'File::Find::Rule' => '0.30',
      'Smart::Comments'   => 0,
      'Test::Simple'     => 0,
	},
   ABSTRACT_FROM => 'lib/File/Find/Rule/DirectoryEmpty.pm',
   AUTHOR => 'Leo Charre leocharre at cpan dot org',
   LICENSE => 'perl',

);
