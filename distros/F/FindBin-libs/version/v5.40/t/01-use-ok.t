package Testophile;

use v5.8;

use Test::More;

my @modz    
= qw
(
    FindBin::Bin 
    FindBin::Parents
    FindBin::libs
);

note "INC is:\n" => explain \@INC;

require_ok  $_, "'$_' required" for @modz;
use_ok      $_,                 for @modz;

done_testing;

__END__
