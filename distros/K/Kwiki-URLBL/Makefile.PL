use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Kwiki::URLBL',
    'VERSION_FROM' => 'lib/Kwiki/URLBL.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
