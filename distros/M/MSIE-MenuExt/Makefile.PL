use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'MSIE::MenuExt',
    'VERSION_FROM' => 'lib/MSIE/MenuExt.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
