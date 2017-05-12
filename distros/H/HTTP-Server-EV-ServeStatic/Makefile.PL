use ExtUtils::MakeMaker;



WriteMakefile(
  'TYPEMAPS' => [],
  'NAME' => 'HTTP::Server::EV::ServeStatic',
  'VERSION' => '0.1',
  'PREREQ_PM' => {
	'HTTP::Server::EV'	=> 0,
	'MIME::Types'		=> 0
  },
);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }