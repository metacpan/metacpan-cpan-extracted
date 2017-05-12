use Test::Simple tests => 6;

use GD::Barcode::Code93;

my $b = GD::Barcode::Code93->new('abc');

ok( ( defined $b and ref $b eq 'GD::Barcode::Code93' ), 'new() ok' );
ok( $b->{text} eq 'ABC', 'init ok' );
ok( $b->calculateSums eq 'ABCHK', 'calculateSums() ok' );
ok( $b->barcode eq '1010111101101010001101001001101000101011001001000110101010111101', 'barcode() ok');

my $img = $b->plot;
ok( ( defined $img and ref $img eq 'GD::Image' ), 'plot() ok' );
ok( length $img == 27, 'image appears correct length' );
