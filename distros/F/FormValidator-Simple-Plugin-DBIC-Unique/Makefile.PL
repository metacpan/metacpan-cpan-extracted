use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'FormValidator::Simple::Plugin::DBIC::Unique',
    VERSION_FROM      => 'lib/FormValidator/Simple/Plugin/DBIC/Unique.pm', # finds $VERSION
    PREREQ_PM         => {
        DBIx::Class => '0.05',
        UNIVERSAL::require => '0',
        FormValidator::Simple => '0.11',
        Scalar::Util => 0,
    }, # e.g., Module::Name => 1.1
);
