use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IO::Select::SSL',
    VERSION_FROM      => 'lib/IO/Select/SSL.pm',
    PREREQ_PM         => {
        'IO::Select'  =>  0,
        'Test'        =>  0,
    },
    ABSTRACT_FROM     => 'lib/IO/Select/SSL.pm',
    AUTHOR            => 'Rob Brown <bbb@cpan.org>',
    LICENSE           => 'artistic_2',
);
