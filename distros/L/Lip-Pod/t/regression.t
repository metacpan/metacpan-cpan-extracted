#!/usr/bin/perl -w
print "1..1\n";
system("perl -I blib/lib blib/script/lip2pod t/hello.t | cmp t/hello.pod");
print "not " if $?;
print "ok 1\n";

