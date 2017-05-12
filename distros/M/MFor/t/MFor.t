use Test::More tests => 70;
BEGIN { use_ok('MFor') };
use lib 'lib/';

use MFor;
use warnings;
use strict;

my $output = '';
open FH , ">" , \$output;
mfor {
  print FH join( '-' , @_ ) . "\n";
} [
    [ 1 .. 3 ],
    [ 1 .. 2 ],
    [ 1 .. 10 ],
];
close FH;

my @lines = split /\n/ , $output;
# warn Dumper( @lines );use Data::Dumper;

for my $e1 ( 1 .. 3 ) {
  for my $e2 ( 1 .. 2 ) {
    for my $e3 ( 1 .. 10 ) {
        my $line = shift @lines;
        chomp $line;
        is ( $line, join ( '-', $e1, $e2, $e3 ) );
    }
  }
}
 
 
$output = '';
open FH , ">" , \$output;
mfor {
  print FH join( '-' , @_ ) . "\n";
} [
    [ 1 .. 3 ],
    [ 1 .. 3 ]
];
close FH;

@lines = split /\n/ , $output;
# warn Dumper( @lines );use Data::Dumper;

for my $e1 ( 1 .. 3 ) {
  for my $e2 ( 1 .. 3 ) {
        my $line = shift @lines;
        chomp $line;
        is ( $line, join ( '-', $e1, $e2 ) , 'test2'  );
  }
}

