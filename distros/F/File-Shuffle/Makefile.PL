
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'File::Shuffle',
    VERSION_FROM => 'lib/File/Shuffle.pm', # finds \$VERSION
    AUTHOR       => 'Jeff Kubina (jeff.kubina@gmail.com)',
    ABSTRACT     => 'Randomly shuffles lines in a file.',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Sort::External' => '0.18',
                     'Data::Dump' => '1.19',
                     'Test::More' => '0.96',
                    },
);
