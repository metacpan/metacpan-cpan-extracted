use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Locale::Framework::gettext',
    'VERSION_FROM'	=> 'lib/Locale/Framework/gettext.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Locale::gettext' => 1.01, 'Locale::Framework' => 0.06 }, 
    'ABSTRACT_FROM'     => 'lib/Locale/Framework/gettext.pm', # retrieve abstract from module
    'AUTHOR'            => 'Hans Oesterholt-Dijkema <oesterhol@cpan.org>',
);

