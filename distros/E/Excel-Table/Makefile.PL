use 5.006004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.


my $preop = 'find $(DISTVNAME) -type f -exec egrep -q Build V1.022 {} \; -exec sed -i "s/___EUMM_VERSION___/Build V$(VERSION)/" {} \; -print ;' .
'perldoc -uT $(DISTVNAME)/$(VERSION_FROM) > $(DISTVNAME)/README.pod';

WriteMakefile(
    NAME              => 'Excel::Table',
    MIN_PERL_VERSION  => '5.006004',
    LICENSE           => 'gpl_2',
    VERSION_FROM      => 'lib/Excel/Table.pm', # finds $VERSION
    PREREQ_PM         => {
        'Data::Dumper' => '0',
        'Spreadsheet::ParseExcel' => '0.57',
        'Spreadsheet::XLSX' => '0',
        'File::Basename' => '0',
        'Carp' => '0',
        'Log::Log4perl' => '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Excel/Table.pm', # retrieve abstract from module
       AUTHOR         => 'tmcmeeki <tmcmeeki@cpan.org>') : ()),
	dist => { PREOP => $preop, },
);
