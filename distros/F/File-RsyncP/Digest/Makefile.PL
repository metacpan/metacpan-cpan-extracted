use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'File::RsyncP::Digest',
    'VERSION_FROM' => 'Digest.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'CONFIG'	=> ['byteorder'],	# Used to determine 64-bitness
    'DEFINE'	=> '-DPERL_BYTEORDER=$(BYTEORDER)',
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'OBJECT'	=> q[Digest$(OBJ_EXT) md4c$(OBJ_EXT) rsync_lib$(OBJ_EXT)],
);
