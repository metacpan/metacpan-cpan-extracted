#!/bin/bash

# run baseline program, 2nd with -o to match outputs more closely to t1,t2
time perl t0.pl > junk0
time perl t0.pl -o > junk0a

# t1 forces non-optimized munging
time `perl t1.pl > junk1 2> warnings`

# t2 uses optimizer 
time `perl t2.pl > junk2 2> warnings`

exit;


THESE TESTS SHOW SOME PROMISING RESULTS:

[jimc@harpo perftests]$ timeit.sh 
Name "main::opt_o" used only once: possible typo at t0.pl line 52.

real	1m9.690s
user	1m3.520s
sys	0m1.744s
Name "main::opt_o" used only once: possible typo at t0.pl line 52.

real	0m52.844s
user	0m50.738s
sys	0m1.566s

real	0m44.532s
user	0m41.195s
sys	0m1.484s


1st test is Log::Log4perl, with usage contortions sufficient to match
tailorability of AutoCategorize (ie category for every call).

2nd test optimizes away some of the get_logger() calls, in an attempt
to be more realistic wrt how it would actually be used.

3rd test is Log::Log4perl::AutoCategorize

results from a P2-400 with 128 MB


Note:

commented case, t1.pl, has optimization defeated (by preventing the
stashing of JIT functions).  It appears to run forever, and chew up
all the memory.  Theres some latent bug, but its not a recommended
usage.


t1.pl still uses optimizer pass (which munges method-name).  The -n
flag causes AUTOLOAD to not save just-built subroutine, which means
its done repeatedly.  This is a teensy bit slower than avoiding the
optimization phase entirely, but it directly shows the gains of
avoiding the repeated AUTOLOAD calls.




