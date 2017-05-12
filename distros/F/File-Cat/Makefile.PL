use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'File::Cat',
    'VERSION_FROM' => 'Cat.pm', # finds $VERSION
	'dist' => { 'COMPRESS' => 'gzip --best' },
);
