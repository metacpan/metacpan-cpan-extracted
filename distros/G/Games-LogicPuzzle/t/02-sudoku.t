# $Id: 02-sudoku.t,v 1.2 2006/01/30 20:04:16 adler Exp $

use Test;
BEGIN { plan tests => 3 };

use Games::LogicPuzzle;
my $p= new Games::LogicPuzzle (
    num_things => 16,
    sameok     => 1,
);

$p->assign( {
    POS=> [ 11,    12,    13,    14,
            21,    22,    23,    24,
            31,    32,    33,    34,
            41,    42,    43,    44, ],
    VAL=>[  1,     2, undef, undef,
            3,     4,     1,     2,
            4,     3,     2, undef,
            2,     1,     4,     3, ],
} );

$p->properties( {
    VAL => [1 .. 4],
} );

$p->verify_proc( \&my_verify );


my $soln= $p->solve();

ok ( $p->get("VAL", "POS" => "13", $soln),  "3" );
ok ( $p->get("VAL", "POS" => "14", $soln),  "4" );
ok ( $p->get("VAL", "POS" => "34", $soln),  "1" );

if (0) {
   # print soln
   for my $y ( 1 .. 4 ) {
      for my $x ( 1 .. 4 ) {
         my $v = $p->get("VAL", "POS" => "$x$y", $soln);
         print " $v ";
         print "|" if $x % 2 ==0;
      }
         print "\n";
         print "-----------------------\n" if $y % 2 ==0;
   }
}


# test whether all the elements in a group are unique
# call as sudoku_test ($c,11,12,21,22)
sub sudoku_test {
   my $c= shift();
   my %vals;

   for (@_) {
     my $val= $c->VAL(POS=>$_);
     next unless $val;
     return 0 if ++$vals{$val} > 1;
   }

   return 1;
}

    

 
sub my_verify
{
    my $c=      shift();

    return 0 unless sudoku_test($c, 11, 12, 21, 22);
    return 0 unless sudoku_test($c, 31, 32, 41, 42);
    return 0 unless sudoku_test($c, 13, 14, 23, 24);
    return 0 unless sudoku_test($c, 33, 34, 43, 44);
    return 0 unless sudoku_test($c, 11, 12, 13, 14);
    return 0 unless sudoku_test($c, 21, 22, 23, 24);
    return 0 unless sudoku_test($c, 31, 32, 33, 34);
    return 0 unless sudoku_test($c, 41, 42, 43, 44);
    return 0 unless sudoku_test($c, 11, 21, 31, 41);
    return 0 unless sudoku_test($c, 12, 22, 32, 42);
    return 0 unless sudoku_test($c, 13, 23, 33, 43);
    return 0 unless sudoku_test($c, 14, 24, 34, 44);
    return 1;
}
