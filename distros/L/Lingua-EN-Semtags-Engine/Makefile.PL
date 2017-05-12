use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Lingua::EN::Semtags::Engine',
	VERSION_FROM => 'lib/Lingua/EN/Semtags/Engine.pm',
	ABSTRACT_FROM => 'lib/Lingua/EN/Semtags/Engine.pm',
	PREREQ_PM => {
		Lingua::EN::Tagger => '0.11', 
		WordNet::QueryData => '1.46'
	},
	AUTHOR => 'Igor Myroshnichenko <igorm@cpan.org>'
);
