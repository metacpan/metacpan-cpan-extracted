use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mindcal',
    VERSION_FROM      => 'Mindcal.pm', # finds $VERSION
    PREREQ_PM         => {
        Log::Log4perl => 1,
        DateTime      => 0.38,
                         },
    'EXE_FILES'    => ['eg/mindcal'],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'Mindcal.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Schilli <m@perlmeister.com>') : ()),

);
