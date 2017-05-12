#!/usr/bin/perl -w

# test for loops

use Test::More;
use strict;

BEGIN
   {
   plan tests => 4;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Devel::Graph") or die($@);
   };

#############################################################################
# croak on errors

my $grapher = Devel::Graph->new();

is (ref($grapher), 'Devel::Graph');
my $for_code = <<'FOR_CODE';
my $a = 1;
for (my $i = 0; $i < 5; $i++)
  {
  my $var = 1;
  my $other_var = 2;
  my $var_now = $var + $other_var;
  print "$var_now\n";
  }
FOR_CODE

eval "\$grapher->decompose( \\\$for_code )";
is ($@, '', '"for" error');

my $until_code = <<'UNTIL_CODE';
my $i = 1;
until ($i < 5)
  {
  $i++;
  my $var = 1;
  my $other_var = 2;
  my $var_now = $var + $other_var;
  print "$var_now\n";
  }
UNTIL_CODE

eval "\$grapher->decompose( \\\$until_code )";
is ($@, '', '"until" error');

print $grapher->as_ascii();


