# -*- perl -*-
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use_ok( 'MM::Table' )               || BAIL_OUT( 'Cannot load Module::Generic' );
    use_ok( 'MM::Const', qw( :table ) ) || BAIL_OUT( "Unable to load Module::Generic::File" );
};

# NOTE: Tests
subtest 'make/copy/clear basics' => sub
{
    my $t = MM::Table->make( undef, 0 );
    ok( $t, 'make() returns object even with nelts 0' );
    isa_ok( $t, 'MM::Table' );

    $t->set( Foo => 'one' );
    $t->add( Foo => 'two' );

    my $copy = $t->copy( undef );
    ok( $copy, 'copy() returns object' );
    isa_ok( $copy, 'MM::Table' );

    is( $copy->get( 'foo' ), 'one', 'copy keeps data (scalar get oldest)' );
    my @vals = $copy->get( 'foo' );
    is_deeply( \@vals, [ 'one', 'two' ], 'copy keeps data (list get all)' );

    $t->clear();
    is( $t->get( 'foo' ), undef, 'clear removes everything' );
    my @none = $t->get( 'foo' );
    is_deeply( \@none, [], 'clear: list context empty' );
};

subtest 'set/add/unset/get ordering + case-insensitive keys' => sub
{
    my $t = MM::Table->make( undef, 10 );

    $t->set( Foo => 'one' );
    $t->add( foo => 'two' );
    $t->add( FOO => 'three' );

    is( $t->get( 'fOo' ), 'one', 'scalar get returns oldest value' );

    my @vals = $t->get( 'foo' );
    is_deeply( \@vals, [ 'one', 'two', 'three' ], 'list get returns all in insertion order' );

    $t->unset( 'FOO' );
    is( $t->get( 'foo' ), undef, 'unset removes all values for key (case-insensitive)' );
};

subtest 'merge semantics (first value only) + missing key' => sub
{
    my $t = MM::Table->make( undef, 10 );

    $t->set( merge => '1' );
    $t->merge( merge => 'a' );
    is( $t->get( 'merge' ), '1, a', 'merge appends to first value using ", "' );

    $t->clear();
    $t->set( merge => '1' );
    $t->add( merge => '2' );
    $t->merge( merge => 'a' );

    my @vals = $t->get( 'merge' );
    is_deeply( \@vals, [ '1, a', '2' ], 'merge affects only first (oldest) value of multivalued key' );

    $t->clear();
    $t->merge( miss => 'a' );
    is( $t->get( 'miss' ), 'a', 'merge on missing key behaves like add()' );
};

subtest 'overlay semantics (new table = overlay first, then base)' => sub
{
    my $base = MM::Table->make( undef, 10 );
    my $add  = MM::Table->make( undef, 10 );

    $base->set( bar => 'beer' );
    $base->set( foo => 'one' );
    $base->add( foo => 'two' );

    $add->set( foo => 'three' );

    my $ov = $base->overlay( $add, undef );

    _pairs_eq(
        _dump_table_pairs( $ov ),
        [
            [ 'foo', 'three' ],
            [ 'bar', 'beer' ],
            [ 'foo', 'one' ],
            [ 'foo', 'two'  ],
        ],
        'overlay pair order'
    );

    # Verify originals unmodified
    _pairs_eq(
        _dump_table_pairs( $base ),
        [
            [ 'bar', 'beer' ],
            [ 'foo', 'one'  ],
            [ 'foo', 'two'  ],
        ],
        'base unmodified after overlay'
    );

    _pairs_eq(
        _dump_table_pairs( $add ),
        [
            [ 'foo', 'three' ],
        ],
        'add unmodified after overlay'
    );
};

subtest 'compress SET (keep last) and MERGE (comma list) with stable order by first occurrence' => sub
{
    my $t = MM::Table->make( undef, 10 );

    $t->set( bar => 'beer' );
    $t->set( foo => 'one' );
    $t->add( foo => 'two' );
    $t->add( foo => 'three' );

    my $t_set = $t->copy( undef );
    $t_set->compress( OVERLAP_TABLES_SET );

    _pairs_eq(
        _dump_table_pairs( $t_set ),
        [
            [ 'bar', 'beer'  ],
            [ 'foo', 'three' ],
        ],
        'compress SET result'
    );

    my $t_merge = $t->copy( undef );
    $t_merge->compress( OVERLAP_TABLES_MERGE );

    _pairs_eq(
        _dump_table_pairs( $t_merge ),
        [
            [ 'bar', 'beer'             ],
            [ 'foo', 'one, two, three'  ],
        ],
        'compress MERGE result'
    );
};

subtest 'overlap SET overwrites key entirely; overlap MERGE merges into first value' => sub
{
    my $base = MM::Table->make( undef, 10 );
    my $add  = MM::Table->make( undef, 10 );

    $base->set( bar => 'beer' );
    $base->set( foo => 'one' );
    $base->add( foo => 'two' );
    $add->set( foo => 'three' );

    my $set = $base->copy( undef );
    $set->overlap( $add, OVERLAP_TABLES_SET );

    _pairs_eq(
        _dump_table_pairs( $set ),
        [
            [ 'bar', 'beer'  ],
            [ 'foo', 'three' ],
        ],
        'overlap SET'
    );

    my $base2 = MM::Table->make( undef, 10 );
    my $add2  = MM::Table->make( undef, 10 );

    $base2->set( foo => 'one' );
    $base2->add( foo => 'two' );
    $add2->set( foo => 'three' );
    $add2->set( bar => 'beer' );

    my $merge = $base2->copy( undef );
    $merge->overlap( $add2, OVERLAP_TABLES_MERGE );

    _pairs_eq(
        _dump_table_pairs( $merge ),
        [
            [ 'foo', 'one, three' ],
            [ 'foo', 'two'        ],
            [ 'bar', 'beer'       ],
        ],
        'overlap MERGE (merge affects oldest foo only, keeps other foo entry)'
    );

    # add table is unmodified
    _pairs_eq(
        _dump_table_pairs( $add2 ),
        [
            [ 'foo', 'three' ],
            [ 'bar', 'beer'  ],
        ],
        'overlap does not modify source table'
    );
};

subtest 'do() filter + early abort' => sub
{
    my $t = MM::Table->make( undef, 10 );

    $t->set( a => 1 );
    $t->set( b => 2 );
    $t->set( c => 3 );
    $t->add( a => 4 );

    my @seen;
    $t->do(
        sub
        {
            push( @seen, [ $_[0], $_[1] ] );
            return 1;
        },
        'a', 'c'
    );

    _pairs_eq(
        \@seen,
        [
            [ 'a', '1' ],
            [ 'c', '3' ],
            [ 'a', '4' ],
        ],
        'do filter (case-insensitive via lc in impl) preserves order and multivalues'
    );

    my $count = 0;
    $t->do(
        sub
        {
            $count++;
            return( $count == 2 ? 0 : 1 );
        }
    );
    is( $count, 2, 'do early abort stops iteration' );
};

subtest 'tied interface: FETCH/STORE/EXISTS/DELETE/CLEAR and each() multivalue FETCH quirk' => sub
{
    my $t = MM::Table->make( undef, 10 );

    $t->{a} = 1;               # STORE => set
    $t->add( b => 2 );
    $t->add( a => 3 );

    ok( exists $t->{a}, 'EXISTS works' );
    is( $t->{a}, '1', 'FETCH returns oldest when not iterating' );

    my( $k1, $v1 ) = each( %$t );   # should be (a, 1)
    is( $k1, 'a', 'each #1 key' );
    is( $v1, '1', 'each #1 value' );
    is( $t->{a}, '1', 'FETCH during each(): at (a,1) returns current value for multivalue key' );

    my( $k2, $v2 ) = each( %$t );   # (b,2)
    is( $k2, 'b', 'each #2 key' );
    is( $v2, '2', 'each #2 value' );
    is( $t->{a}, '1', 'FETCH during each(): while at (b,2), {a} returns oldest' );

    my( $k3, $v3 ) = each( %$t );   # (a,3)
    is( $k3, 'a', 'each #3 key' );
    is( $v3, '3', 'each #3 value' );
    is( $t->{a}, '3', 'FETCH during each(): at second (a,3) returns current (quirk)' );

    my( $k4, $v4 ) = each( %$t );
    is( $k4, undef, 'each ends (key)' );
    is( $v4, undef, 'each ends (value)' );
    is( $t->{a}, '1', 'FETCH after each() ends returns oldest again' );

    delete $t->{a};
    ok( !exists $t->{a}, 'DELETE removes all values for key' );

    $t->{x} = 'y';
    ok( exists $t->{x}, 'STORE after delete works' );

    %$t = ();
    is( $t->get( 'x' ), undef, 'CLEAR via %$t=() works' );
};

done_testing();

# NOTE: Helpers
sub _dump_table_pairs
{
    my( $t ) = @_;

    my @pairs;
    $t->do(sub
    {
        push( @pairs, [ $_[0], $_[1] ] );
        return 1;
    });

    return( \@pairs );
}

sub _pairs_eq
{
    my( $got, $exp, $label ) = @_;

    is( scalar( @$got ), scalar( @$exp ), "$label: pair count" ) || return;

    for( my $i = 0; $i < scalar( @$exp ); $i++ )
    {
        is( $got->[$i]->[0], $exp->[$i]->[0], "$label: key[$i]" );
        is( $got->[$i]->[1], $exp->[$i]->[1], "$label: val[$i]" );
    }

    return;
}

__END__

