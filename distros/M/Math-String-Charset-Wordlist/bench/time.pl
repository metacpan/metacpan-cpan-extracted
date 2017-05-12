#!/usr/bin/perl -w

use Time::HiRes qw/time/;

use Math::String;
use Math::String::Charset::Wordlist;

print "Math::String::Charset::Wordlist v",
      $Math::String::Charset::Wordlist::VERSION,"\n";

my $t1 = time();
my $cs =
  Math::String::Charset::Wordlist->new( { file => shift || 'big.lst' }  );
my $t2 = time() - $t1;

print "new() took $t2 seconds.\n";

$t1 = time();
print "contains ",$cs->class(1)," words.\n";
$t2 = time() - $t1;
print "FETCHALL took $t2 seconds.\n";

$t1 = time();
print "contains ",$cs->class(1)," words.\n";
$t2 = time() - $t1;
print "FETCHALL took $t2 seconds.\n";

$t1 = time();
print "contains ",$cs->class(1)," words.\n";
$t2 = time() - $t1;
print "FETCHALL took $t2 seconds.\n";

sleep(100);
