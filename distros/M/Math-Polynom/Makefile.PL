use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Math::Polynom',
    VERSION_FROM      => 'lib/Math/Polynom.pm', # finds $VERSION
    PREREQ_PM         => {
	accessors => '0',
	constant  => '0',
	Data::Dumper => '2.10',
        Carp => '0',
	Data::Float => '0',
	Scalar::Util => '1.14',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Math/Polynom.pm', # retrieve abstract from module
       AUTHOR         => 'Erwan Lemonnier <erwan@cpan.org>') : ()),
);
