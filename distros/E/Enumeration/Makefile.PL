use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Enumeration',
    VERSION_FROM      => 'lib/Enumeration.pm', # finds $VERSION
    PREREQ_PM         => {
                          # Before v6.25, MakeMaker tries to run Build.PL.
                          'ExtUtils::MakeMaker' => '6.25',
                         },
    (MM->can('signature_target')? (SIGN => 1) : ()),
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Enumeration.pm', # retrieve abstract from module
       AUTHOR         => 'eroode <roode@cpan.org>') : ()),
);
