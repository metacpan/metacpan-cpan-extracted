use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Mail::QmailRemoteXS',
    'VERSION_FROM' => 'QmailRemoteXS.pm', # finds $VERSION
    'AUTHOR' => 'Reed Sandberg',
    'LIBS'	=> ['-lresolv'],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'MYEXTLIB' => 'qmailrem/libqmailrem$(LIB_EXT)',
);


sub MY::postamble {
'
$(MYEXTLIB): qmailrem/Makefile
	cd qmailrem && $(MAKE) $(PASSTHRU)
';
}

