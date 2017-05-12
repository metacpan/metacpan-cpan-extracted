#!perl -T

use Test::More;
use Format::Human::Bytes;

my %Checks = (
    ''              => ['0','0.0','0.00'],
    0               => ['0','0.0','0.00'],
    1               => ['1B','1.0B','1.00B'],
    2048            => ['2048B','2048.0B'],
    65536           => ['64kB','64.0kB','64.00kB'],
    131072          => ['128kB','128.0kB'],
    900000          => ['879kB','878.9kB','878.91kB','878.906kB'],
    900000000       => ['858MB','858.3MB','858.31MB','858.307MB'],
    900000000000    => ['838GB','838.2GB','838.19GB','838.190GB','838.1903GB'],
    900000000000000 => ['819TB','818.5TB','818.55TB','818.545TB','818.5452TB'],
);

my $Count;
for (values(%Checks)) { $Count += scalar(@{$_}); }
plan tests => 1 + (3 * $Count);

my $fhb = Format::Human::Bytes->new();
ok( defined($fhb), 'Create object' );

# Function tests
for my $Num ( sort( keys(%Checks) ) ) {
    for my $Dec ( 0 .. $#{ $Checks{$Num} } ) {
        is(
            Format::Human::Bytes::base2( $Num, $Dec ),
            $Checks{$Num}->[$Dec],
            'Function, ' . $Dec . ' decimals: ' . $Num . ' = ' . $Checks{$Num}->[$Dec]
        );
        is(
            Format::Human::Bytes->base2( $Num, $Dec ),
            $Checks{$Num}->[$Dec],
            'Class method, ' . $Dec . ' decimals: ' . $Num . ' = ' . $Checks{$Num}->[$Dec]
        );
        is(
            $fhb->base2( $Num, $Dec ),
            $Checks{$Num}->[$Dec],
            'Object method, ' . $Dec . ' decimals: ' . $Num . ' = ' . $Checks{$Num}->[$Dec]
        );
    }
}
