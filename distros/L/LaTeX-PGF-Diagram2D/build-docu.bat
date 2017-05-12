@ECHO OFF
set LO=-interaction=batchmode
cd examples
ECHO Processing test001a.pl
perl test001a.pl
ECHO Processing test002a.pl
perl test002a.pl
ECHO Processing test003a.pl
perl test003a.pl
ECHO Processing test004a.pl
perl test004a.pl
ECHO Processing test005a.pl
perl test005a.pl
ECHO Processing test006a.pl
perl test006a.pl
ECHO Processing test007a.pl
perl test007a.pl
ECHO Processing test008a.pl
perl test008a.pl
ECHO Processing test009a.pl
perl test009a.pl
ECHO Processing test011a.pl
perl test011a.pl
ECHO Processing test012a.pl
perl test012a.pl
ECHO Processing test013a.pl
perl test013a.pl
ECHO Processing test014a.pl
perl test014a.pl
ECHO Processing test015a.pl
perl test015a.pl
ECHO Processing test016a.pl
perl test016a.pl
ECHO Processing test017a.pl
perl test017a.pl
ECHO Processing test018a.pl
perl test018a.pl
ECHO Processing test019a.pl
perl test019a.pl
ECHO Processing test020a.pl
perl test020a.pl
ECHO Processing test021a.pl
perl test021a.pl
ECHO Processing test022a.pl
perl test022a.pl
ECHO Processing test023a.pl
perl test023a.pl
ECHO Processing test024a.pl
perl test024a.pl
ECHO Processing xstest01.pl
perl xstest01.pl
cd ..
cd doc-src
pdflatex diagram-en && pdflatex %LO% diagram-en && pdflatex %LO% diagram-en && move diagram-en.pdf ..
pdflatex diagram-de && pdflatex %LO% diagram-de && pdflatex %LO% diagram-de && move diagram-de.pdf ..
cd ..
