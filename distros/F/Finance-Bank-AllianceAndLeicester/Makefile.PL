use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Finance::Bank::AllianceAndLeicester',
    VERSION_FROM      => 'lib/Finance/Bank/AllianceAndLeicester.pm', # finds $VERSION
    PREREQ_PM         => { WWW::Mechanize => 0, HTML::TokeParser => 0 },
    AUTHOR            => 'Ian Bissett <ian@tekuiti.co.uk>'	
);
