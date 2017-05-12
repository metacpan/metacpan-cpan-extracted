use ExtUtils::MakeMaker;
# See lib/ExtUtils/Makeaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'    => 'Exporter::Dispatch',
    'VERSION_FROM' => 'lib/Exporter/Dispatch.pm',
    'PREREQ_PM' => {},
    ($] >= 5.005 ?    # Add these new keywords supported since 5.005
# retrieve abstract from module
      (ABSTRACT_FROM => 'lib/Exporter/Dispatch.pm',
       AUTHOR     => 'Joseph F. Ryan <ryan.311@osu.edu>') : ()),
);

