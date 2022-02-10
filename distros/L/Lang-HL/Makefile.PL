use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lang::HL',
    VERSION_FROM      => 'lib/Lang/HL.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {'Perl::Tidy' => 0, 'Regexp::Grammars' => 0, 'Lang::HL::Export' => 0, 'Data::Printer' => 0}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Lang/HL.pm', # retrieve abstract from module
    AUTHOR            => 'Rajkumar Reddy',
    EXE_FILES         => ['script/hlc', 'script/hlp'],
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
