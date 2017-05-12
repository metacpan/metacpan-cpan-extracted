use ExtUtils::MakeMaker;

#use Cwd qw(abs_path); 
WriteMakefile(
    clean => { 'FILES'	=> '*~ *.inl core test*.txt *.tar.gz _Inline ' },
    'PREREQ_PM' => { 'Inline'	   => '0.43',
		     'Test::More'  => '0.72'},
    dist => { 'TARFLAGS'	=> 'cvf',
              'COMPRESS'        => 'gzip -9f',
    		'SUFFIX'	=> '.tgz'},
    'NAME'	=> 'Inline::BC',
    'VERSION_FROM' => 'BC.pm',
    'DEFINE'	=> '',   
    'MYEXTLIB'	=> 'mylib/libbc$(LIB_EXT)',   
    'LIBS'	=> '-lfl',   
    'INC'	=> '-Imylib',
);

sub MY::postamble {
       '
$(MYEXTLIB): mylib/Makefile
	cd mylib && $(MAKE) $(PASSTHRU)
';
}
