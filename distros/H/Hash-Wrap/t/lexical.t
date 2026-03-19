#! perl

use Test2::V0;

BEGIN {
skip_all "Perl >= v5.38 is required for -lexical; current perl is $^V"
  if $] < 5.038;
}

{
    package P1;
    use Hash::Wrap ( { -lexical => 1 } );
    sub wrap_wrap_hash { goto \&wrap_hash }
}

my %hash = ( a => 1, b => 2 );

like( dies { P1::wrap_hash() }, qr{undefined subroutine}i, q[not available outside of package] );

my $q;
ok( lives { $q = P1::wrap_wrap_hash( \%hash ) }, 'available inside of package' );
is( $q->b, 2, 'value' );

done_testing;
