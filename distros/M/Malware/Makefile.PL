use 5.008007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Malware',
    VERSION_FROM      => 'lib/Malware.pm', # finds $VERSION
    PREREQ_PM         => {Archive::Extract => undef, Net::Protocol::Simple => 1.00, Net::Connection::Simple => 1.00, Time::Timestamp => 1.0, Text::Table => 1.107, Class::ParmList => undef}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Malware.pm', # retrieve abstract from module
       AUTHOR         => 'Wes Young <wcyoung@buffalo.edu>') : ()),
);
