use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Kwiki::Footnote',
    'VERSION_FROM' => 'lib/Kwiki/Footnote.pm', # finds $VERSION
    'PREREQ_PM' => {
	Kwiki => 0.37,
	Test::More => 0.32,
    },
);
