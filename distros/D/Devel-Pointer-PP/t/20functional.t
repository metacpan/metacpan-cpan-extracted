use strict;
use Test::More tests => 8;

BEGIN { use_ok( 'Devel::Pointer::PP' ) }

{
    my $a = 42;
    is( 0+\$a, address_of( $a ) );
}

{
    my $a = 42;
    is( \$a, deref( address_of( $a ) ) );
    is( $a, ${deref( address_of( $a ) )} );
}

{
    my $a = 42;
    is( \$a, deref( \ $a ) );
    is( $a, ${deref( \ $a )} );
}

{
    my $a = 42;
    is( \$a, deref( "" . \ $a ) );
    is( $a, ${deref( "" . \ $a )} );
}
