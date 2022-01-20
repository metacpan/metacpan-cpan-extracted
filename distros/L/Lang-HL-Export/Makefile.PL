use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lang::HL::Export',
    VERSION_FROM      => 'lib/Lang/HL/Export.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {'Hash::Merge' => 0}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Lang/HL/Export.pm', # retrieve abstract from module
    AUTHOR            => 'pc <pc@>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
