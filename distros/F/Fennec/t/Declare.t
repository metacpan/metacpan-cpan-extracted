package TEST::Fennec::Declare;
use strict;
use warnings;

BEGIN {
    my $ok = eval { require Fennec::Declare; 1 };
    return if $ok;

    require Test::More;
    Test::More->import( skip_all => 'Fennec::Declare not installed' );
}

use Fennec::Declare;

tests group1 {
    ok( 1, "Here" );
}

ok( 1, "there" );

describe more {
    tests deep {
        ok( 1, 'everywhere' );
    }
}

done_testing(
    sub {
        my $runner = Fennec::Runner->new();
        my $want   = 5;
        my $got    = $runner->collector->test_count;
        return if $runner->collector->ok( $got == $want, "Got expected test count" );
        $runner->collector->diag("Got:  $got\nWant: $want");
    }
);
