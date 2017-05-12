use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

warn "Warning: this module is desigend for MacOS-X (not $^O). It will probably not work.\n"
	if ($^O !~ /darwin/i);

WriteMakefile(
    NAME              => 'Mac::Tie::PList',
    VERSION_FROM      => 'lib/Mac/Tie/PList.pm',
    PREREQ_PM         => {
	'Carp'        => 1.03,
	'Foundation'  => 1.0,
	'Tie::Hash'   => 1.01,
	'Tie::Array'  => 1.03,
	'Tie::Scalar' => 1.00,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mac/Tie/PList.pm', # retrieve abstract from module
       AUTHOR         => 'Gavin Brock <gbrock@cpan.org>') : ()),
);
