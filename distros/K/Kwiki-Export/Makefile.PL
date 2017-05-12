use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Kwiki::Export',
    'VERSION_FROM' => 'lib/Kwiki/Export.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
        Kwiki => 0,
        HTML::WikiConverter => 0.50,
        Archive::Any::Create => 0,
    },
);
