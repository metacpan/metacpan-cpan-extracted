use 5.008007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
    (
     NAME              => 'GPS::Tracer',
     VERSION_FROM      => 'lib/GPS/Tracer.pm', # finds $VERSION
     EXE_FILES        => [ qw( scripts/fetch_and_create ) ],
     PREREQ_PM        => { 'Text::CSV::Simple' => 0,
			   'XML::Simple'       => 0,
			   'LWP::UserAgent'    => 0,
			   'File::Temp'        => 0,
			   'Date::Calc'        => 0,
			   'GD::Graph'         => 0 },
     ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/GPS/Tracer.pm', # retrieve abstract from module
       AUTHOR         => 'Martin Senger <martin.senger@gmail.com>') : ()),
     );
