use 5.006;
use strict;
use warnings FATAL => "all";
use Test::More;
 
BEGIN {
    foreach my $module (
        "", "::Script", "::Dataset", "::PartiallyKeyedList",
        "::PrototypedData", "::Process", "::Util"
    ) {
        use_ok('Gnuplot::Builder' . $module);
    }
}
 
diag( "Testing Gnuplot::Builder $Gnuplot::Builder::VERSION, Perl $], $^X" );
done_testing;
