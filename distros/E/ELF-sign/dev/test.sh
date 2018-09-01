make clean; perl Makefile.PL && make install && gcc -o dev/test dev/test.c && perl dev/test.pl
rm dev/test
