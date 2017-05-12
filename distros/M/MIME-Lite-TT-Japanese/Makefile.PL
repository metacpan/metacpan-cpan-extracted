use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'MIME::Lite::TT::Japanese',
    'VERSION_FROM' => 'lib/MIME/Lite/TT/Japanese.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	MIME::Lite::TT => '0',
	Jcode => '0',
    DateTime::Format::Mail => '0',
    },
);
