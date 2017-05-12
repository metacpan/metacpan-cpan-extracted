use 5.008;              # required version of Perl
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   NAME              => 'Math::BigInt::Random::OO',
   VERSION_FROM      => 'lib/Math/BigInt/Random/OO.pm',
   PREREQ_PM         => {
                         Test::More => 0.94    # for the 'subtest' function
                        },
   ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/Math/BigInt/Random/OO.pm',
     AUTHOR         => 'Peter J. Acklam <pjacklam@cpan.org>') : ()),
  );
