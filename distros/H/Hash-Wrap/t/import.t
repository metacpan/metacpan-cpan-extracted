#! perl

use Test2::V0;

{
    package P1;

    use Hash::Wrap;
}

my %hash = ( a => 1, b => 2 );

my $q = P1::wrap_hash( \%hash );

ok (
   lives { $q->a },
   'use Hash::Wrap;'
) or note $@;


{
    package P2;

    use Hash::Wrap ();
}

like (
    dies { P2::wrap_hash( ) },
      qr/undefined subroutine/i,
      q[don't export]
    );

done_testing;
