use ExtUtils::MakeMaker;
WriteMakefile (
    AUTHOR        => 'Nathan Wiger (nate@wiger.org)',
    NAME          => 'HTML::PhotoAlbum',
    VERSION_FROM  => 'lib/HTML/PhotoAlbum.pm', # finds $VERSION
    PREREQ_PM     => {
        'CGI::FormBuilder' => '3.000',
    }
);
