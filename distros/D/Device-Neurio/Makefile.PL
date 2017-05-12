use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::Neurio',
    VERSION_FROM      => 'lib/Device/Neurio.pm', # finds $VERSION
    PREREQ_PM   => {
	  'LWP::UserAgent' => '6.05', # or a minimum working version
      'JSON'           => '2.90',
      'MIME::Base64'   => '3.14',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Device/Neurio.pm', # retrieve abstract from module
       AUTHOR         => 'Kedar Warriner') : ()),
);

#example of how to get module version
#perl -MDateTime::Format::ISO8601 -e 'print "$DateTime::Format::ISO8601::VERSION\n"'
