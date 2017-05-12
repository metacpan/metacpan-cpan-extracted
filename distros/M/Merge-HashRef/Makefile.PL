use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Merge::HashRef',
    'VERSION_FROM'	=> 'HashRef.pm', # finds $VERSION
    'PREREQ_PM'		=> { Exporter::Simple => 1.10,
			     Test::Class      => 0.03 },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      ( AUTHOR     => 'Stray Toaster <coder@stray-toaster.co.uk>') : ()),
);
