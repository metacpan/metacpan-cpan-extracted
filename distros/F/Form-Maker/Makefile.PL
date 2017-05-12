use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Form::Maker',
    VERSION_FROM      => 'lib/Form/Maker.pm', # finds $VERSION
    PREREQ_PM         => {
        Email::Valid => 0.15,
        HTML::Element => 0,
        Test::More => 0,
        Class::Data::Inheritable => 0,
        Module::Pluggable => 0,
        UNIVERSAL::moniker => 0,
        UNIVERSAL::require => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Form/Maker.pm', # retrieve abstract from module
       AUTHOR         => 'simon <simon@>') : ()),
);
