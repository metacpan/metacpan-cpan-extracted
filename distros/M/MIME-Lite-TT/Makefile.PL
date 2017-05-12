use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'MIME::Lite::TT',
    'VERSION_FROM' => 'lib/MIME/Lite/TT.pm', # finds $VERSION
    'PREREQ_PM' => { Test::More => 0.32,
					 MIME::Lite => 0,
					 Template => 0,
    },
);
