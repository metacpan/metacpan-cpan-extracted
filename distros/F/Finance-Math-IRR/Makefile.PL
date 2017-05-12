use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Finance::Math::IRR',
    VERSION_FROM      => 'lib/Finance/Math/IRR.pm', # finds $VERSION
    PREREQ_PM         => {
	Math::Polynom => 0.06,
	Date::Calc    => 5.4,
	Scalar::Util  => 1.18,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Finance/Math/IRR.pm', # retrieve abstract from module
       AUTHOR         => 'Erwan Lemonnier <erwan@cpan.org>') : ()),
);
