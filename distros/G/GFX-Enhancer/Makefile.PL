use 5.032000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'GFX::Enhancer',
    VERSION_FROM      => 'lib/GFX/Enhancer.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => { Image::PNG => 0.24, Evo::EA => 0.1.5 }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/GFX/Enhancer.pm', # retrieve abstract from module
    AUTHOR            => 'koboldwiz <koboldwiz@yahoo.com>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #https://metacpan.org/pod/Module::Build::API
);
