use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'File::Lock',
 	'VERSION_FROM' => 'Lock.pm',
   # 'LIBS'	=> ['-lbsd -lucb'],	# e.g., '-lm' 
    'DEFINE'	=> '',			# e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',			# e.g., '-I/usr/include/other' 
);
