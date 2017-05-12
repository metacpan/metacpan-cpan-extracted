use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Finance::Bank::ES::INGDirect',
    VERSION_FROM      => 'lib/Finance/Bank/ES/INGDirect.pm', # finds $VERSION
    PREREQ_PM         => { WWW::Mechanize => 0,
                           Digest::MD5 => 0,
		           HTML::Tree => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Finance/Bank/ES/INGDirect.pm', # retrieve abstract from module
       AUTHOR         => 'Bruno Diaz <brunodiaz@cpan.org>') : ()),
);
