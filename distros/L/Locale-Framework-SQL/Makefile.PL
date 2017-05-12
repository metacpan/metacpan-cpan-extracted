use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Locale::Framework::SQL',
    'VERSION_FROM'	=> 'lib/Locale/Framework/SQL.pm', # finds $VERSION
    'PREREQ_PM'		=> { DBI => 1.3, Locale::Framework => 0.06 }, 
    'ABSTRACT_FROM'     => 'lib/Locale/Framework/SQL.pm', # retrieve abstract from module
    'AUTHOR'            => 'Hans Oesterholt-Dijkema <oesterhol@cpan.org>',
);
