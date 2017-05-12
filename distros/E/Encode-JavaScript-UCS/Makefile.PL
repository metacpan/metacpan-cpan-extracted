use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Encode::JavaScript::UCS',
    'VERSION_FROM' => 'lib/Encode/JavaScript/UCS.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
        Encode => 2.12,
    },
);
