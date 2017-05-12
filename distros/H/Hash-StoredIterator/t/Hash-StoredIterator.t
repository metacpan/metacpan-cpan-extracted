use Test2::Bundle::Extended -target => 'Hash::StoredIterator';
use Test2::Tools::Spec;

use Hash::StoredIterator ':all';

my %hash = ( a => 1, b => 2, c => 3 );

my @want_outer = (
    [a => 1],
    [b => 2],
    [c => 3],
);

my @want_inner = (
    [a => 1],
    [a => 1],
    [a => 1],
    [b => 2],
    [b => 2],
    [b => 2],
    [c => 3],
    [c => 3],
    [c => 3],
);

describe eaches => sub {
    my $interference;

    case no_interference => sub {
        $interference = sub { 1 };
    };

    # In the interference case, this sub which uses keys, values, and each on
    # our hash is called nested inside our custom calls, they should not
    # interfere as they would with builtins.
    case interference => sub {
        $interference = sub {
            my @garbage = keys(%hash), values(%hash);
            while ( my ( $k, $v ) = each(%hash) ) {
                # Effectively do nothing
                my $foo = $k . $v;
            }
        };
    };

    tests nested_eich => sub {
        my @inner;
        my @outer;

        warnings {
            my $o_it;
            while ( my ( $k, $v ) = eich( %hash, $o_it ) ) {
                push @outer => [$k, $v];
                $interference->();

                my $i_it;
                while ( my ( $k, $v ) = eich( %hash, $i_it ) ) {
                    push @inner => [$k, $v];

                    $interference->();
                }
            }
        };

        is(
            [sort { $a->[0] cmp $b->[0] } @outer],
            \@want_outer,
            "Out loop got all keys"
        );

        is(
            [sort { $a->[0] cmp $b->[0] } @inner],
            \@want_inner,
            "Inner loop got all keys multiple times"
        );
    };

    tests nested_hmap => sub {
        my @inner;
        my @outer;

        #<<< no-tidy  Perltidy hates this...
        hmap {
            my ( $k, $v ) = @_;
            ok( $k, "Got key" );
            ok( $v, "Got val" );
            is( $k, $_, '$_ is set to key' );
            is( $k, $a, '$a is set to key' );
            is( $v, $b, '$b is set to val' );

            push @outer => [$k, $v];
            $interference->();

            hmap {
                my ( $k2, $v2 ) = @_;

                is( $k2, $_, '$_ is set to key' );
                is( $k2, $a, '$a is set to key' );
                is( $v2, $b, '$b is set to val' );

                push @inner => [$k, $v];

                $interference->();
            } %hash;

            is( $k, $_, '$_ is not squashed by inner loop' );
            is( $k, $a, '$a is not squashed by inner loop' );
            is( $v, $b, '$a is not squashed by inner loop' );
        } %hash;
        #>>>

        is(
            [sort { $a->[0] cmp $b->[0] } @outer],
            \@want_outer,
            "Outer loop got all keys"
        );

        is(
            [sort { $a->[0] cmp $b->[0] } @inner],
            \@want_inner,
            "Inner loop got all keys multiple times"
        );
    };
};

tests get_from_eich => sub {
    my $i;
    my $h = {%hash};

    warnings {
        my ( $k, $v ) = eich( %$h, $i );
        ok( $k, "Got a key" );
        ok( $v, "got a value" );
    };
};

tests keys_and_vals => sub {
    is(
        [sort( hkeys(%hash) )],
        [sort keys %hash],
        "Same list from both keys and hkeys"
    );

    is(
        [sort( hvalues(%hash) )],
        [sort values %hash],
        "Same list from both values and hvalues"
    );
};

tests death => sub {
    my $counter = 0;

    my %hash = map { $_ => $_ } 'a' .. 'z';

    # Set an initial iterator
    my ($garbage) = each(%hash);

    #<<< no-tidy  Perltidy hates this...
    eval {
        hmap {
            my ( $k, $v ) = @_;
            die "foo" if $counter++ > 3;
        } %hash;
    };
    #>>>

    like( $@, qr/foo/, "Got error" );

    # Get key at current iteration, it should match the second key
    my ($key) = each(%hash);
    my ( $fkey, $skey ) = keys(%hash);
    is( $garbage, $fkey, "First key matches initial garbage key" );
    is( $key,     $skey, "Iterator was restored" );
};

tests strange_edge_case => { todo => "Not sure what the problem is here..." } => sub {
    is(
        [sort hkeys %hash],
        [sort keys %hash],
        "Same list from both keys and hkeys"
    );

    is(
        [sort hkeys(%hash)],
        [sort keys %hash],
        "Same list from both keys and hkeys"
    );
};

tests iterator => sub {
    my $i = iterator %hash;

    my $nh = {
        $i->(),
        $i->(),
        $i->(),
    };

    is(
        $nh,
        \%hash,
        "Copied hash via iterator"
    );

    is(
        [$i->()],
        [],
        "End, no more"
    );

    my ($k, $v) = $i->();
    ok( $k && $v, "Got a key and value, iterator was reset" );
};

done_testing;
