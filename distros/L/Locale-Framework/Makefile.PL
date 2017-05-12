use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Locale::Framework',
    'VERSION_FROM'	=> 'lib/Locale/Framework.pm', # finds $VERSION
    'PREREQ_PM'		=> { }, 
    'ABSTRACT_FROM'     => 'lib/Locale/Framework.pm', # retrieve abstract from module
    'AUTHOR'            => 'Hans Oesterholt-Dijkema <oesterhol@cpan.org>',
);
