use Test::More tests => 71;
qw(no_plan);

use_ok( 'Math::Business::Stochastic' );

my $stoc = new Math::Business::Stochastic;
ok( (ref $stoc) eq 'Math::Business::Stochastic' );

ok( not defined $stoc->query_k );
ok( not defined $stoc->query_d );
ok( not defined $stoc->query_sd );

my ($k, $d, $sd) = (5, 3, 3);
set_days $stoc $k, $d, $sd;

my @high_values = qw(
    3 5 5 6 6 5 7 5 8 5 7
    8 6 8 6 8 7 8 8 9 8 9
);
my @low_values = qw(
    2 4 3 5 3 5 3 4 5 3 4
    4 5 6 6 6 6 6 7 7 6 7
);
my @close_values = qw(
    3 4 4 5 6 5 6 5 5 5 5
    6 6 6 6 7 7 7 8 8 8 8
);

for(my $i=0 ; $i<int(@close_values) ; $i++) {
    $stoc->insert( $high_values[$i], $low_values[$i], $close_values[$i] );
    if( $k-1 <= $i ) { like( $stoc->query_k, qr/^[\d-.]+$/ ) }
    else             { ok( not defined $stoc->query_k ) }
    if( $k+$d-2 <= $i ) { like( $stoc->query_d, qr/^[\d-.]+$/ ) }
    else                { ok( not defined $stoc->query_d ) }
    if( $k+$d+$sd-3 <= $i ) { like( $stoc->query_sd, qr/^[\d-.]+$/ ) }
    else                    { ok( not defined $stoc->query_sd ) }
}
