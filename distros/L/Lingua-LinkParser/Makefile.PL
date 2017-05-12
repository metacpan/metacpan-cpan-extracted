use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'         => 	"Lingua::LinkParser",
    'VERSION_FROM' => 	"lib/Lingua/LinkParser.pm",
    'DEFINE'	   => 	"-DDICTIONARY_DIR=\\\".\\\"", 

     ## if your libs are in a nonstandard location, changes these, i.e.:
     # 'LIBS'	   => 	"-L/dbrian/link-grammar-4.4.3/link-grammar/.libs/ -llink-grammar", 
    'LIBS'	   => 	"-L/usr/local/lib/ -llink-grammar", 
    'INC'	   => 	"-I/usr/local/include/link-grammar/ -I/usr/local/include/",
    'OBJECT'       => 	"",
);

