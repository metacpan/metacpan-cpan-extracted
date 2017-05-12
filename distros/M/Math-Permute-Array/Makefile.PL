use 5.009000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              NAME               => 'Math::Permute::Array',
              CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 0 },
              BUILD_REQUIRES     => {"strict" => 0, "warnings" => 0, "Exporter" => 0 },
              PREREQ_PM => {
                      # Require Test::More at least 0.47
                      "Test::More" => "0",
                      "Test::Pod"  => "1.00",
                      "Test::Pod::Coverage"  => "1.00",
                      },
              VERSION_FROM       => 'lib/Math/Permute/Array.pm', # finds $VERSION
              MIN_PERL_VERSION   => '5.6.1',
              ABSTRACT_FROM      => 'lib/Math/Permute/Array.pm', # retrieve abstract from module
              AUTHOR             => 'jean-noel quintin <jnquintin@local>',
              LICENSE            => 'perl',
  );
