#!perl -w

print "1..1\n";

use strict;
use IO::String;

my $str = "abcd";

my $destroyed = 0;

{
    package MyStr;
    @MyStr::ISA = qw(IO::String);

    sub DESTROY {
	$destroyed++;
	print "DESTROY @_\n";
    }
}


my $rounds = 5;

for (1..$rounds) {
   my $io = MyStr->new($str);
   die unless $io->getline eq "abcd";
   $io->close;
   undef($io);
   print "-\n";
}

print "XXX $destroyed\n";

print "not " unless $destroyed == $rounds;
print "ok 1\n";
