use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Dua',
    'VERSION_FROM' => 'Dua.pm', # finds $VERSION
    'LIBS'	=> ['-L/bham/pd/packages/ldap-3.1/lib -lldap -llber'], # e.g.,'-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '-Idualib -I/bham/pd/packages/ldap-3.1/include', 
    'MYEXTLIB'  => 'dualib/libdua$(LIB_EXT)',
    'clean'      => { FILES => 'dualib/*.o dualib/*.a' },
);

sub MY::postamble {
'
$(MYEXTLIB): dualib/Makefile dualib/dua.c dualib/dua.h
	cd dualib && $(MAKE)

';
}
