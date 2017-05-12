require 5.6.0;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Games::Object',
    'VERSION_FROM'	=> 'Object.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'IO::String' => 1.02 },
    ( $] >= 5.005 ?
      ( ABSTRACT_FROM	=> 'Object.pod',
        AUTHOR     	=> 'Peter J. Stewart <p.stewart@comcast.net>') : ()
      ),
);
