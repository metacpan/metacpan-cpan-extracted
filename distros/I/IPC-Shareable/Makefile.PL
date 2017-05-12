use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              NAME         => 'IPC::Shareable',
              VERSION_FROM => 'lib/IPC/Shareable.pm',
              LIBS         => [''],
              DEFINE       => '',
              INC          => '',
              PREREQ_PM    => { 
                               "Storable" => 0.607,
                               "Scalar::Util" => 0,
                               "IPC::Semaphore" => 0,
              },
);
