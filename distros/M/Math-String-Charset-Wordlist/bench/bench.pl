#!/usr/bin/perl -w

use Time::HiRes qw/time/;

use Math::String;
use Math::String::Charset::Wordlist;
use Benchmark;

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

#my $x = Math::String->new('',$cs);
#my $y = Math::String->new('',$cs)->last(1);

timethese ( -3,
  {
  fetch_rand => sub { $cs->num2str(int(rand(100000))); },
  fetch_1 => sub { $cs->num2str(1); },
  find => sub { $cs->str2num( $cs->num2str(int(rand(100000))) ); },
  last => sub { $cs->last(1); },
  #next => sub { $x->binc(); },
  #prev => sub { $x->bdec(); },
  } );
