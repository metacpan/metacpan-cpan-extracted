use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Email::Filter::Rules',
    VERSION_FROM => 'lib/Email/Filter/Rules.pm',        # finds $VERSION
    AUTHOR       => 'Jeff Bisbee (jbisbee@cpan.org)',
    ABSTRACT     =>
        'Simple Rules for Routing Mail with Email::Filter/Mail::Audit',
    PREREQ_PM => {
        'Test::Simple'  => 0.44,
        'Email::Filter' => 0,
    },
    LICENSE => 'perl',
);
