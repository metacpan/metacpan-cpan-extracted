#!/usr/bin/perl -w

use strict;
my $give_help = 0;
my $pl_file = shift;
my $c_file = shift;
my $c_var = shift;

$give_help ||= ( !defined $pl_file or
                !defined $c_file or
                !defined $c_var );
$pl_file ||= '';
$c_file ||= '';
$give_help ||= !-f $pl_file;
if( $give_help ) {
  print <<EOT;
Usage: $0 file.pl file.c c_variable
EOT

  exit 1;
}

open IN, "< $pl_file" or die "open '$pl_file': $!";
open OUT, "> $c_file" or die "open '$c_file': $!";
binmode IN; binmode OUT;

# read perl file
undef $/;
my $pl_text = <IN>;
close IN;

#  make a c-array
my @chars = split '', $pl_text;
sub map_fun { local $_ = $_[0];
              m/[\\"']/ and return "\\$_";
              ord() >= 32 && ord() <= 127 && return $_;
              return sprintf '\0%o', ord };

my @c_chars = map { map_fun($_) } @chars;
my $c_arr = "static char $c_var\[] = { " .
  ( join ', ', map { "'$_'" } @c_chars ) .
  ", '\\0' };\n";

print OUT $c_arr;
close OUT;

# local variables:
# mode: cperl
# end:
