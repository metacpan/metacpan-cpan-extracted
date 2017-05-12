#!perl -T

use Test::More;
use Format::Human::Bytes;

my %Checks = (
    ''              => ['0','0.0','0.00'],
    0               => ['0','0.0','0.00'],
    1               => ['1B','1.0B','1.00B'],
    2048            => ['2048B','2048.0B'],
    123456          => ['123kB','123.5kB','123.46kB'],
    65536           => ['66kB','65.5kB','65.54kB'],
    131072          => ['131kB','131.1kB'],
    900000          => ['900kB','900.0kB','900.00kB','900.000kB'],
    900000000       => ['900MB','900.0MB','900.00MB','900.000MB'],
    900000000000    => ['900GB','900.0GB','900.00GB','900.000GB','900.0000GB'],
    900000000000000 => ['900TB','900.0TB','900.00TB','900.000TB','900.0000TB'],
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
            Format::Human::Bytes::base10( $Num, $Dec ),
            $Checks{$Num}->[$Dec],
            'Function, ' . $Dec . ' decimals: ' . $Num . ' = ' . $Checks{$Num}->[$Dec]
        );
        is(
            Format::Human::Bytes->base10( $Num, $Dec ),
            $Checks{$Num}->[$Dec],
            'Class method, ' . $Dec . ' decimals: ' . $Num . ' = ' . $Checks{$Num}->[$Dec]
        );
        is(
            $fhb->base10( $Num, $Dec ),
            $Checks{$Num}->[$Dec],
            'Object method, ' . $Dec . ' decimals: ' . $Num . ' = ' . $Checks{$Num}->[$Dec]
        );
    }
}
