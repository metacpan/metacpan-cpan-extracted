#!perl

use 5.14.0;
use warnings;

use File::ReplaceBytes;
use Test::Most;    # plan is down at bottom

my $deeply = \&eq_or_diff;

package Scalarton {
    my $x;
    sub FETCH     { $x }
    sub STORE     { $x = '(' . $_[1] . ')' }
    sub TIESCALAR { bless \$_[1], $_[0] }
}
tie my $corbata, 'Scalarton';
$corbata = "blue";
is( $corbata, '(blue)', 'tied variable' );

#use Devel::Peek qw(Dump);
#diag Dump $corbata;

open my $fh, '<', 't/testdata' or die "could not read t/testdata: $!\n";

my $st = File::ReplaceBytes::pread( $fh, $corbata, 8, 8 );
$deeply->( [ $corbata, $st ], [ '(bbbbbbbb)', 8 ], 'read bx8' );

#diag Dump $corbata;

open $fh, '+>', 'out-tie' or die "could not write 'out-tie': $!\n";

$st = File::ReplaceBytes::pwrite( $fh, $corbata, 0, 0 );
is( $st, length $corbata, 'pwrite some bytes' );

my $written = do { local $/ = undef; readline $fh };
is( $written, '(bbbbbbbb)' );

done_testing(4);
