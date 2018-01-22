use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'File::Copy::Recursive',
    VERSION_FROM => 'lib/File/Copy/Recursive.pm',
    PREREQ_PM    => {
        File::Copy      => 0,
        File::Spec      => 0,
        Test::More      => 0,
        Test::Deep      => 0,
        Test::File      => 0,
        File::Temp      => 0,
        Test::Warn      => 0,
        File::Glob      => 0,
        Test::Exception => 0,
        Cwd             => 0,
        File::Spec      => 0,
        Path::Tiny      => 0,
    },
    (
        $] >= 5.005
        ? (
            ABSTRACT_FROM => 'lib/File/Copy/Recursive.pm',
            AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>'
          )
        : ()
    ),
);
