use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Math::NumberBase',
    VERSION_FROM => 'lib/Math/NumberBase.pm', # finds $VERSION
    PREREQ_PM    => {'Test::NoWarnings' => '0.084'}, # e.g., Module::Name => 1.1
    (
        $] >= 5.005        ## Add these new keywords supported since 5.005
        ? (
            ABSTRACT_FROM  => 'lib/Math/NumberBase.pm', # retrieve abstract from module
            AUTHOR         => 'Yehezkiel Syamsuhadi <yehezkielbs@gmail.com>'
        )
        : ()
    ),
);
