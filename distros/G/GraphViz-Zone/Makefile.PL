use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'GraphViz::Zone',
    'VERSION_FROM' => 'Zone.pm', # finds $VERSION
    'PREREQ_PM' => { GraphViz => 0 } );
