use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'HTML::XSSLint',
    'VERSION_FROM' => 'lib/HTML/XSSLint.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Test::More' => 0.32,
	'LWP' => 0,
	'HTML::Form' => 0,
	'Digest::MD5' => 0,
	'IO::String' => 0,
    },
    'EXE_FILES' => [
	'bin/xsslint',
    ],
);
