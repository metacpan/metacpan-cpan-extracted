
# File : Makefile.PL
use ExtUtils::MakeMaker;
WriteMakefile(

     'NAME'    => 'GFL',                  # Name of package
     'AUTHOR' => 'Germain Garand (germain@ebooksfrance.com)',
     'ABSTRACT' => 'Interface to P-e Gougelet\'s GFL Library',
     'VERSION_FROM' => 'GFL/Image.pm', 
     'LIBS'    => ['-lgfl -lm'],                    # Name of custom libraries
     'OBJECT'  => 'libgfl_wrap.o'  # Object files
);
                        
                        
