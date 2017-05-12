use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	    => 'File::RsyncP::FileList',
    'VERSION_FROM'  => 'FileList.pm', # finds $VERSION
    'LIBS'	    => ['-lm'], # e.g., '-lm'
    'DEFINE'	    => '-DPERL_BYTEORDER=$(BYTEORDER)',
    'INC'	    => '',     # e.g., '-I/usr/include/other' 
    'NORECURS'      => 1,
    'OBJECT'	    => q[FileList$(OBJ_EXT)
                         exclude$(OBJ_EXT)
                         flist$(OBJ_EXT)
                         hlink$(OBJ_EXT)
                         pool_alloc$(OBJ_EXT)
                         snprintf$(OBJ_EXT)
                         wildmatch$(OBJ_EXT)
                        ],
    'depend'        => { 'FileList.o' => 'config.h' },
    'clean'         => {FILES => "configure.in config.log config.status config.h conftest* confdefs*"},
);

sub MY::postamble
{
    return <<EOF;

config.h: config.h.in
	./configure
EOF
}
