set -x 
PERL_DL_NONLAZY=1 /usr/bin/perl -Iblib/arch -Iblib/lib -I/usr/lib/perl5/5.6.0/i386-linux -I/usr/lib/perl5/5.6.0 -e 'use Test::Harness qw(&runtests $verbose); $verbose=0; runtests @ARGV;' supertest/*.t
