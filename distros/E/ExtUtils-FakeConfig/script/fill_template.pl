#!/usr/bin/perl -w

use strict;

my( $input, $spec, $output ) = @ARGV;
my( %values );

foreach ( @ARGV ) {
  m/^(\w+)\=(.*)$/ and $values{$1} = $2;
}

open IN, "< $input" or die "Unable to open '$input'";
open SPEC, "< $spec" or die "Unable to open '$spec'";
open OUTPUT, "> $output" or die "Unable to open '$output'";

$values{spec} = join '', <SPEC>;

while( defined( $_ = <IN> ) ) {
  $_ =~ s/--(\w+)--/$values{$1}/ge;
  print OUTPUT $_;
}

close IN;
close SPEC;
close OUTPUT;

exit 0;
