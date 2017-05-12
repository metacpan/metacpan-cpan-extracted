use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Math::Matlab::Engine',
    'VERSION_FROM'	=> 'lib/Math/Matlab/Engine.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Math/Matlab/Engine.pm', # retrieve abstract from module
       AUTHOR     => 'Oliver Ebenhoeh <oliver.ebenhoeh@rz.hu-berlin.de>') : ()),
    'LIBS'		=> ['-L/usr/global/matlab6/extern/lib/glnx86 -lmx -leng'], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> '-I/usr/global/matlab6/extern/include', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
