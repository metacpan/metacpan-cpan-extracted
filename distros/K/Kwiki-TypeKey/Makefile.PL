use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Kwiki::TypeKey',
    'VERSION_FROM' => 'lib/Kwiki/TypeKey.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	Authen::TypeKey => 0.02,
	Kwiki => 0.38,
	Spoon => 0.22,
	Kwiki::UserName => 0.14,
    },
);
