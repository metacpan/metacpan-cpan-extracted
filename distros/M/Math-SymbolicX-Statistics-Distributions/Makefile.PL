use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Math::SymbolicX::Statistics::Distributions',
    VERSION_FROM      => 'lib/Math/SymbolicX/Statistics/Distributions.pm',
    PREREQ_PM         => {
    'Math::Symbolic' => '0.128',
    'Math::SymbolicX::ParserExtensionFactory' => '0.01',
    # stupid module doing magic at compile time:
    'Test::LectroTest' => '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Math/SymbolicX/Statistics/Distributions.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <symbolic-module at steffen-mueller dot net>') : ()),
);
