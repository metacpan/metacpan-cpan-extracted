use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Gtk2::GladeXML::OO',
    'VERSION_FROM'	=> 'lib/Gtk2/GladeXML/OO.pm', # finds $VERSION
    'PREREQ_PM'     => { 
							'Gtk2::GladeXML'	=> 1.0, 
							'XML::LibXML'		=> 1.75,
					}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR		=> '£ukasz Strzelecki <strzelec@rswsystems.pl>') : ()),
	
);
