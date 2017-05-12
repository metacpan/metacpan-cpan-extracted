use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Kwiki::OpenSearch::Service',
    'VERSION_FROM' => 'lib/Kwiki/OpenSearch/Service.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	Kwiki => 0.37,
    },
);
