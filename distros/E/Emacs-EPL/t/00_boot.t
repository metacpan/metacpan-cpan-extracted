# -*-perl-*-

BEGIN { $^W = 1; $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Emacs::Lisp;
$loaded = 1;
print "ok 1\n";

unless (&eq (1, 1)) { print "not " }
print "ok 2\n";
&garbage_collect;
