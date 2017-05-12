use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Kwiki::OpenSearch',
    'VERSION_FROM' => 'lib/Kwiki/OpenSearch.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
