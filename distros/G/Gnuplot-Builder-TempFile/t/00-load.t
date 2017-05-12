use 5.006;
use strict;
use warnings;
use Test::More;
 
BEGIN {
    use_ok('Gnuplot::Builder::TempFile');
    use_ok('Gnuplot::Builder::Wgnuplot');
}
 
diag( "Testing Gnuplot::Builder::TempFile $Gnuplot::Builder::TempFile::VERSION, Perl $], $^X" );

done_testing;
