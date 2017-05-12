use 5.006; # means 5.6 basically
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'IOC',
    VERSION_FROM => 'lib/IOC.pm', 
    PREREQ_PM    => {
        'Test::More'             => 0.47,
        'Test::Exception'        => 0.15,
        'Scalar::Util'           => 1.10,
        'Class::Throwable'       => 0.04,
        'Class::Interfaces'      => 0.01,
        'Class::StrongSingleton' => 0.01,
        'XML::SAX'               => 0.12
    }
);
