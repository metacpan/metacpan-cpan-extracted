use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'     => 'GD::Graph::XY',
  'VERSION'  => '0.92', 
  'DISTNAME' => 'GDGraph-XY',
  ($] ge '5.005') ? 
  (
    'AUTHOR'   => 'George A. Fitch III (aka Gaffer), gaf3@gaf3.com',
    'ABSTRACT' => 'XY Graphs for GD::Graph',
  ) : (),
  'PREREQ_PM' => 
  { 
    'GD' => 1.18,
    'GD::Graph' => 1.30,
   },
  'PM' => {
    'xylines.pm' => '$(INST_LIBDIR)/xylines.pm',
    'xypoints.pm' => '$(INST_LIBDIR)/xypoints.pm',
    'xylinespoints.pm' => '$(INST_LIBDIR)/xylinespoints.pm',
  }
);

