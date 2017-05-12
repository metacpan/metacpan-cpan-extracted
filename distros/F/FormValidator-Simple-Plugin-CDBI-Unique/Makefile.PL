use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'FormValidator::Simple::Plugin::CDBI::Unique',
    VERSION_FROM      => 'lib/FormValidator/Simple/Plugin/CDBI/Unique.pm', # finds $VERSION
    PREREQ_PM         => {
        FormValidator::Simple => 0.11,
        SQL::Abstract => 0,
        Class::DBI => 0.96,
    }, # e.g., Module::Name => 1.1
);
