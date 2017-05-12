use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Mail::Address::MobileJp',
    'VERSION_FROM' => 'lib/Mail/Address/MobileJp.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	Mail::Address => 0,
    },
);
