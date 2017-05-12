use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'     => 'GD::Graph::boxplot',
  'VERSION'  => '1.00', 
  'DISTNAME' => 'GDGraph-boxplot',
  ($] ge '5.005') ? 
  (
    'AUTHOR'   => 'Nigel Wright (nwright@hmc.edu)',
    'ABSTRACT' => 'Produces PNG box and whisker graphs',
  ) : (),
  'PREREQ_PM' => 
  { 
    'GD' => 1.18,
    'GD::Graph' => 1.30,
    'Statistics::Descriptive' => 2.4
   },
  'PM' => {
    'boxplot.pm' => '$(INST_LIBDIR)/boxplot.pm',
  }
);

