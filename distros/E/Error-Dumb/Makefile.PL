use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'      	=> 'Error::Dumb',
    'VERSION_FROM'      => 'Dumb.pm', # finds $VERSION
    'ABSTRACT_FROM'     => 'Dumb.pm',
);
