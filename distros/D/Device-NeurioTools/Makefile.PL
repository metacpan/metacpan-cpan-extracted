use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::NeurioTools',
    VERSION_FROM      => 'lib/Device/NeurioTools.pm', # finds $VERSION
    PREREQ_PM   => {
      'Device::Neurio'            => '0.10',
      'Time::Local'               => '1.2000',
      'DateTime::Format::ISO8601' => '0.08', # or a minimum working version
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Device/NeurioTools.pm', # retrieve abstract from module
       AUTHOR         => 'Kedar Warriner') : ()),
);

#example of how to get module version
#perl -MDateTime::Format::ISO8601 -e 'print "$DateTime::Format::ISO8601::VERSION\n"';
