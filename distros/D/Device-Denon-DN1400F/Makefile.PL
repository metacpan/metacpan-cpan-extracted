use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Device::Denon::DN1400F',
    'VERSION_FROM'	=> 'DN1400F.pm', # finds $VERSION
    'PREREQ_PM'		=> {
				'Device::SerialPort'	=> 0.22,
					},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'DN1400F.pm', # retrieve abstract from module
       AUTHOR     => 'Shevek <shevek@cpan.org>') : ()),
);
