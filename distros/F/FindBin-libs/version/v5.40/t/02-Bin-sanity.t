package Testophile;

use v5.8;
use lib;

use Test::More;

my $madness = 'FindBin::Bin';
my @importz = qw( $Bin &Bin );

note "INC is:\n" => explain \@INC;

use_ok $madness => @importz;

ok "$Bin"   , "\$Bin is defined ($Bin)";
ok Bin      , "Bin is executable ($Bin)";

is Bin(), $Bin, "Bin returns '$Bin'";

done_testing;

__END__
