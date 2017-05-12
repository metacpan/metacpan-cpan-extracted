use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	   => 'GD::Graph::Map',
    'VERSION_FROM' => 'lib/GD/Graph/Map.pm', # finds $VERSION
);

sub MY::postamble {
  '
samples ::
	@cd samples && $(MAKE) all
  ';   
}
