use ExtUtils::MakeMaker;

sub MY::postamble { <<'.'; }

dist_both : dist ppmdist 

ppmdist : ppd pure_all
	$(TAR) $(TARFLAGS) $(DISTNAME).ppm.tar blib
	$(RM_RF) blib
	$(RM_RF) pm_to_blib
	$(COMPRESS) $(DISTNAME).ppm.tar
.

WriteMakefile(
  NAME	          => 'Mail::MsgStore',
  AUTHOR          => 'v (v@rant.scriptmania.com)',
  VERSION_FROM    => 'MsgStore.pm', 
  ABSTRACT_FROM   => 'MsgStore.pm',
  BINARY_LOCATION => 'Mail-MsgStore.ppm.tar.gz',
  PREREQ_PM       => 
  {
    'Carp'            => 0,
    'File::Find'      => 0,
    'File::Path'      => 0,
    'MailTools'       => 0,
    'Net::LDAP'       => 0,
    'Net::POP3'       => 2.20,
    'Time::ParseDate' => 0,
    'Sys::UniqueID'   => 0,
  },
  dist            => 
  {
    TAR      => 'C:\\progra~1\\util\\tar.exe',
    TARFLAGS => 'cvf',
    COMPRESS => 'C:\\progra~1\\util\\gzip.exe --best',
    SUFFIX   => '.gz',
  },
);
