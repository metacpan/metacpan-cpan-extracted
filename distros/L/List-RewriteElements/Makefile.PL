#$Id: Makefile.PL 1120 2006-12-31 16:20:24Z jimk $


use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'List::RewriteElements',
    VERSION_FROM => 'lib/List/RewriteElements.pm', # finds \$VERSION
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Create a new list by rewriting elements of a first list',
    PREREQ_PM    => {
                     'Carp'             => 0,
                     'Cwd'              => 0,
                     'File::Basename'   => 0,
                     'File::Copy'       => 0,
                     'File::Spec'       => 0,
                     'File::Temp'       => 0,
                     'Test::Simple'     => 0.44,
                     'Tie::File'        => 0,
                    },
);
