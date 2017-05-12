use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MassSpec::ViewSpectrum',
    VERSION_FROM      => 'lib/MassSpec/ViewSpectrum.pm', # finds $VERSION
    PREREQ_PM         => {GD::Graph => 1.43}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MassSpec/ViewSpectrum.pm', # retrieve abstract from module
       AUTHOR         => 'Jonathan Epstein <Jonathan_Epstein@nih.gov>') : ()),
);
