use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'HTML::Template::Associate',
    VERSION_FROM => 'lib/HTML/Template/Associate.pm', # finds $VERSION
    AUTHOR       => 'Alex Pavlovic (alex.pavlovic@taskforce-1.com)',
    ABSTRACT     => '',
    PREREQ_PM    => {
	'Test::Simple' => 0.44,
        'Data::FormValidator' => 0,
        'HTML::Template' => 0,
        'CGI' => 0,
        'Test::More' => 0
    },
);
