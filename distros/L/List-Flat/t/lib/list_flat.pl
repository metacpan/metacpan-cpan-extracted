
# tests to be attempted by all permutations of loading

deep_test_both( ['j'], ['j'], 'Flatten single scalar' );

deep_test_both( [qw/k l m n o p/], [qw/k l m n o p/], 'Flatten simple list' );

deep_test_both( [ [ [ [qw/q r/] ] ] ], [qw/q r/], 'Flatten nested arrayrefs' );

my @complex = ( qw/a b/, [ qw/c d/, [qw/e f/], 'g' ], 'h' );
my @flat_complex = (qw/a b c d e f g h/);

deep_test_both( \@complex, \@flat_complex, 'Flatten complex array' );

my @sublist       = (qw/w x y/);
my @repeated      = ( qw/z AA/, \@sublist, qw/BB/, \@sublist );
my @flat_repeated = (qw/z AA w x y BB w x y/);

deep_test_both( \@repeated, \@flat_repeated,
    'Flatten complex array with repeated sublists' );

my @circlist = (qw/CC DD EE/);
push @circlist, \@circlist;
my @test_circlist = flat(qw/CC DD EE/);
my @flat_circlist = (qw/CC DD EE/);

deep_test_flat_r( \@test_circlist, \@flat_circlist,
    'flat_r: Flatten array with circular reference' );

SKIP: {

    skip( 'Test::Fatal not loaded', 1 )
      unless eval { require Test::Fatal; 1 };

    my $x = Test::Fatal::exception( sub { flat(@circlist); } );
    like( $x, qr/Circular reference/i, 'flat() dies with circular reference' );

}

require Scalar::Util;

my $blessed = bless [ 't', ['u'] ], 'Dummyclass';

my @blessed_list       = ( 's', $blessed, 'v' );
my @test_blessed_list  = flat(@blessed_list);
my @testf_blessed_list = flat_f(@blessed_list);
my @testr_blessed_list = flat_r(@blessed_list);

is( (Scalar::Util::blessed ($blessed_list[1])),
    (Scalar::Util::blessed ($test_blessed_list[1])),
    "flat: Blessed member is not flattened"
);

is( (Scalar::Util::blessed ($blessed_list[1])),
    (Scalar::Util::blessed ($testr_blessed_list[1])),
    "flat_r: Blessed member is not flattened"
);

is( (Scalar::Util::blessed ($blessed_list[1])),
    (Scalar::Util::blessed ($testf_blessed_list[1])),
    "flat_f: Blessed member is not flattened"
);

sub deep_test_both {
    deep_test_flat(@_);
    deep_test_flat_r(@_);
    deep_test_flat_f(@_);
}

sub deep_test_flat {

    my @list        = @{ +shift };
    my @flat        = @{ +shift };
    my $description = shift;

    my @flattened_array     = flat(@list);
    my $flattened_scalarref = flat(@list);

    is_deeply( \@flat, \@flattened_array, "flat, list context: $description" );
    is_deeply( \@flat, $flattened_scalarref,
        "flat, scalar context: $description" );

    return;

}

sub deep_test_flat_r {

    my @list        = @{ +shift };
    my @flat        = @{ +shift };
    my $description = shift;

    my @flattened_array     = flat_r(@list);
    my $flattened_scalarref = flat_r(@list);

    is_deeply( \@flat, \@flattened_array, "flat, list context: $description" );
    is_deeply( \@flat, $flattened_scalarref,
        "flat, scalar context: $description" );

    return;

}

sub deep_test_flat_f {

    my @list        = @{ +shift };
    my @flat        = @{ +shift };
    my $description = shift;

    my @flattened_array     = flat_f(@list);
    my $flattened_scalarref = flat_f(@list);

    is_deeply( \@flat, \@flattened_array,
        "flat_f, list context: $description" );
    is_deeply( \@flat, $flattened_scalarref,
        "flat_f, scalar context: $description" );

    return;

}

1;
