#!/usr/bin/perl -w

# test for Math::String and Math::String::Charset

BEGIN { unshift @INC, '../lib'; }

use Math::String;
use Math::String::Charset;
use strict;

my $count = shift || 4000;

my @words;
open FILE, 'wordlist.txt' or die "Can't read wordlist.txt: $!\n";
while (<FILE>)
  {
  chomp $_; push @words, $_;
  }
close FILE;
my $cs = new Math::String::Charset ( { start => \@words, sep => ' ', } );

my $string = Math::String->new('',$cs);

my $cmp = $ARGV[0] || "";
print "# Generating first $count strings:\n";
for (my $i = 0; $i < $count; $i++)
  {
  #$string++;
  print ++$string,"\n";
  #print "'$string' is the ",$string->as_number(),"th in list\n"
  # if ($string eq $cmp);
  }
print "# Done. Now converting arguments to number:\n";

foreach (@ARGV)
  {
  chomp();
  $string = Math::String->new($_,$cs);
  print "'$_' is the ",$string->as_number(),"th in list\n";
  }
print "Error: ",$cs->error(),"\n" if $cs->error() ne "";
print "# Done.\n";
