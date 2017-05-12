use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::Nest',
    VERSION_FROM      => 'lib/Device/Nest.pm', # finds $VERSION
    PREREQ_PM   => {
	  'LWP::UserAgent' => '6.05', # or a minimum working version
      'JSON'           => '2.90',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Device/Nest.pm', # retrieve abstract from module
       AUTHOR         => 'A. U. Thor <pi@>') : ()),
);

#example of how to get module version
#perl -MDateTime::Format::ISO8601 -e 'print "$DateTime::Format::ISO8601::VERSION\n"'
