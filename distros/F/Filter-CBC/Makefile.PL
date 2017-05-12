use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Filter::CBC',
    VERSION_FROM      => 'lib/Filter/CBC.pm', # finds $VERSION
    'PREREQ_PM' => {
         'Filter::Util::Call' => '1.05',
         'Crypt::CBC'         => '1.25',
	 'Crypt::Rijndael'    => '0.04',
     },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Filter/CBC.pm', # retrieve abstract from module
       AUTHOR         => 'Hendrik Van Belleghem <hendrik@apple.com>') : ()),
);
