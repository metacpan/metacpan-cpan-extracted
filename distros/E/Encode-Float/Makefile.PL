use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Encode::Float',
    VERSION_FROM => 'lib/Encode/Float.pm', # finds \$VERSION
    AUTHOR       => 'Jeff Kubina (jeff.kubina@gmail.com)',
    ABSTRACT     => 'Encode/decode float as a string for sorting.',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
    LICENSE      => 'perl',
);
