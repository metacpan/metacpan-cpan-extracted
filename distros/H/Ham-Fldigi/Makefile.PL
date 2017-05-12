use 5.012004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Ham::Fldigi',
    VERSION_FROM      => 'lib/Ham/Fldigi.pm', # finds $VERSION
    PREREQ_PM         => {
													'Moose'							=> '2.0402',
													'Data::GUID'				=> '0.046',
													'RPC::XML::Client'	=> '1.39',
													'Time::HiRes'				=> '1.9719',
													'Term::ReadLine'		=> '1.07',
													'Switch'						=> '2.16',
													'Term::ANSIColor'		=> '2.02',
													'DateTime'					=> '0.72',
													}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Ham/Fldigi.pm', # retrieve abstract from module
       AUTHOR         => 'Andy Smith <andy@m0vkg.org.uk>') : ()),
);
