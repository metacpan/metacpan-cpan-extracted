use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Filter::BoxString',
    VERSION_FROM      => 'lib/Filter/BoxString.pm', # finds $VERSION
    PREREQ_PM         => {
        'Filter::Simple' => 0,
        'Test::More'     => 0, 
        'Text::Balanced' => '2.0.0', 
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Filter/BoxString.pm', # retrieve abstract from module
       AUTHOR         => 'Dylan Doxey <dylan.doxey@gmail.com>') : ()),
);
