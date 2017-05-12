use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		    => 'MIME::Structure',
    'AUTHOR'        => 'Paul Hoffman <nkuitse AT cpan DOT org>',
    'VERSION_FROM'	=> 'lib/MIME/Structure.pm',
    'PREREQ_PM'     => {
        'Text::Balanced' => 0,
    },
);

