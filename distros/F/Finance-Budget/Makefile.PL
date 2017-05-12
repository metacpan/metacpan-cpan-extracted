use 5.022001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Finance::Budget',
    VERSION_FROM      => 'lib/Finance/Budget.pm',
    PREREQ_PM         => {
        'Date::Manip' => '6.52',
        'File::Slurp' => '9999.19',
        'Text::CSV'   => '1.33',
    },
    ABSTRACT_FROM     => 'lib/Finance/Budget.pm', # retrieve abstract from module
    AUTHOR            => 'Dylan Doxey <dylan@cpan.org>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
