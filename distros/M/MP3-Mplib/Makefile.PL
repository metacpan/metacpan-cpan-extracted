use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'MP3::Mplib',
    'VERSION_FROM'	=> 'Mplib.pm', 
    'PREREQ_PM'		=> { 'Test::More' => 0 },
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'Mplib.pm', # retrieve abstract from module
       AUTHOR     => 
          'Tassilo v. Parseval <tassilo.von.parseval@rwth-aachen.de>') : ()),
    'LIBS'		=> [], 
    'DEFINE'	=> $] < 5.006 ? '-DFIX_ANTIQUE_PERL' : '', 
    'INC'		=> '',
    'MYEXTLIB'  => 'mplib/mplib$(LIB_EXT)',
    'OPTIMIZE'  => '-O3',
    'clean'       => { FILES => 'MP3-Mplib-* t/test_cp.mp3' },
);

sub MY::postamble {
    '
$(MYEXTLIB): mplib/Makefile
	cd mplib && $(MAKE) $(PASSTHRU)
';
}
