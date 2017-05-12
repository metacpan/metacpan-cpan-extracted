use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'File::BSDGlob',
    'DISTNAME'  => 'File-BSDGlob',
    'VERSION_FROM' => 'BSDGlob.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 

## uncomment for glob debugging
## note that this will cause make test to fail
#    'DEFINE'	=> '-DGLOB_DEBUG',
#    'OPTIMIZE'  => '-g',

    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'OBJECT'	=> 'bsd_glob$(OBJ_EXT) BSDGlob$(OBJ_EXT)',
    'dist'      => {
        COMPRESS     => 'gzip -9',
        SUFFIX       => 'gz',
        DIST_DEFAULT => 'all tardist',
    },
);
