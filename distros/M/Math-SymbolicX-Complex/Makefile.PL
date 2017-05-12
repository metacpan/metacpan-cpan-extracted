use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Math::SymbolicX::Complex',
    'VERSION_FROM' =>
      'lib/Math/SymbolicX/Complex.pm',    # finds $VERSION
    'LICENSE' => 'perl',
    'PREREQ_PM' => {
  Test::More => 0.44,
  Math::SymbolicX::ParserExtensionFactory => 0.01,
  Math::Symbolic => 0.129,
    },    # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM => 'lib/Math/SymbolicX/Complex.pm',
            AUTHOR        =>
              'Steffen Mueller <symbolic-module at steffen-mueller dot net>'
          )
        : ()
    ),

);
