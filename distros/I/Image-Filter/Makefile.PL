use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Image::Filter',
    'VERSION_FROM'	=> 'Filter.pm', # finds $VERSION
    'LIBS'		=> ['-lgd -ljpeg -lpng -lm'], # e.g., '-lm'
    'OBJECT'		=> '$(O_FILES)', # link all the C files too
    'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'},
);
