make realclean
rm MANIFEST
rm META.*
rm MYMETA.*
rm *.tar.gz
perl Makefile.PL
make manifest
make dist
