use ExtUtils::MakeMaker;

WriteMakefile(
    clean => { 'FILES'	=> '*~ *.inl core test*.txt *.tar.gz _Inline ' },
    dist => { 'TARFLAGS'	=> 'cvf',
              'COMPRESS'        => 'gzip -9f',
    		'SUFFIX'	=> '.tgz'},
    'NAME'	=> 'Jabber::Reload',
    'VERSION_FROM' => 'Reload.pm',
    'DEFINE'	=> '',   
);
