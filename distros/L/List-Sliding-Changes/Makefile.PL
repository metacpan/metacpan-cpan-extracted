use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME          => 'List::Sliding::Changes',
    VERSION_FROM  => 'lib/List/Sliding/Changes.pm', # finds $VERSION
    ABSTRACT_FROM => 'lib/List/Sliding/Changes.pm', # retrieve abstract from module
    AUTHOR        => 'Max Maischein <corion@cpan.org>',
    PREREQ_PM     => {
                        Test::More => 0,
                      }, # e.g., Module::Name => 1.1
);

1;
