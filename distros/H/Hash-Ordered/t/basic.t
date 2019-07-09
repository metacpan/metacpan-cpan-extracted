use 5.006;
use strict;
use warnings;
use Test::More 0.96;
use Test::FailWarnings;
use Test::Deep '!blessed';
use Test::Fatal;
binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

use Hash::Ordered;

use constant HO => "Hash::Ordered";

subtest "constructors" => sub {

    my $hash;

    $hash = new_ok( HO, [], "new()" );
    cmp_deeply( [ $hash->keys ],   [], "empty keys" );
    cmp_deeply( [ $hash->values ], [], "empty values" );

    $hash = new_ok( HO, [ a => 1, b => 2 ], "new( \@pairs )" );
    cmp_deeply( [ $hash->keys ],   [qw/a b/], "keys ordered as expected" );
    cmp_deeply( [ $hash->values ], [qw/1 2/], "values ordered as expected" );

    like(
        exception { HO->new("a") },
        qr/requires key-value pairs/,
        "unbalanced args throws exception"
    );

    for my $size ( 10, 1000 ) {

        $hash = new_ok( HO, [ 1 .. $size * 2 ] );
        $hash->delete(3); # trigger tombstone on large hash

        my $clone = $hash->clone;
        cmp_deeply( [ $clone->as_list ], [ $hash->as_list ], "clone() returns copy" );

        my $same = $hash->clone( $hash->keys );
        cmp_deeply( [ $same->as_list ], [ $hash->as_list ], "clone( keys )" );

        my $rev = $hash->clone( reverse $hash->keys );
        my $expected = [ map { $_ => $hash->get($_) } reverse $hash->keys ];
        cmp_deeply( [ $rev->as_list ], $expected, "clone( reverse keys )" );

        my $filter = $hash->clone('5');
        cmp_deeply( [ $filter->as_list ], [ 5 => 6 ], "clone( '5' )" );

        my $extra = $hash->clone( 'c', '1' );
        cmp_deeply( [ $extra->as_list ], [ c => undef, 1 => 2 ], "clone( 'c', '1' )" );

    }

    $hash = new_ok( HO, [ a => 1, b => 2, a => 2 ] );
    cmp_deeply( [ $hash->keys ],   [qw/a b/], "keys ordered as expected" );
    cmp_deeply( [ $hash->values ], [qw/2 2/], "values ordered as expected" );

};

subtest "overloading" => sub {

    my $hash = new_ok( HO, [], "new()" );
    ok( !$hash, "empty hash is boolean false" );
    $hash->set( a => 1 );
    ok( !!$hash, "non-empty hash is boolean true" );

    $hash = new_ok( HO, [], "new()" );

    like(
        "$hash",
        qr/\AHash::Ordered=ARRAY\(0x[0-9a-f]+\)\z/,
        "stringified gives typical Perl object string form"
    );

    like( 0+ $hash, qr/\A\d+\z/, "numified gives typical Perl object decimal address" );

};

subtest "element methods" => sub {

    for my $size ( 10, 1000 ) {

        my $hash = new_ok( HO, [ 1 .. $size * 2 ] );
        $hash->delete(3); # trigger tombstone on large hash

        my @keys   = $hash->keys;
        my @values = $hash->values;

        ok( !$hash->exists("a"), "exists is false for non-existing element" );
        is( $hash->get("a"), undef, "get on non-existing element returns undef" );
        is( $hash->set( "a", 1 ), 1, "set on non-existing element returns new value" );
        is( $hash->get("a"), 1, "get on existing element returns value" );
        ok( $hash->exists("a"), "exists is true for existing element" );

        is( $hash->set( "b", 2 ), 2, "set another key" );
        cmp_deeply( [ $hash->keys ],   [ @keys,   qw/a b/ ], "keys ordered as expected" );
        cmp_deeply( [ $hash->values ], [ @values, qw/1 2/ ], "values ordered as expected" );

        is( $hash->delete("a"), 1,     "delete existing key returns old value" );
        is( $hash->delete("z"), undef, "delete non-existing key returns undef" );

        is( $hash->set( "b", 9 ), 9, "set existing key" );
        is( $hash->set( "c", 3 ), 3, "set another non-existent key" );
        cmp_deeply( [ $hash->keys ],   [ @keys,   qw/b c/ ], "keys ordered as expected" );
        cmp_deeply( [ $hash->values ], [ @values, qw/9 3/ ], "values ordered as expected" );

        {
            my @warnings;
            local $SIG{__WARN__} = sub { push @warnings, @_; return };
            $hash->set( undef, 42 );
            is( $hash->get(undef), 42, "undef is an acceptable key" );
            for (@warnings) {
                like( $_, qr/uninitialized value/, "undef warning" );
            }
        }
    }
};

subtest "output and iteration" => sub {

    my $hash = new_ok( HO, [ 'a' .. 'z' ], "new('a'..'z')" );

    cmp_deeply( [ $hash->as_list ], [ 'a' .. 'z' ], "as_list" );

    cmp_deeply(
        [ $hash->as_list(qw/a c g zz/) ],
        [ a => 'b', c => 'd', g => 'h', zz => undef ],
        "as_list( keys )"
    );

    my @slice = $hash->values(qw/a c zz g/);
    cmp_deeply( \@slice, [ 'b', 'd', undef, 'h' ], "values( keys )" );

    my $iter = $hash->iterator;
    my @saw;
    while ( my ( $k, $v ) = $iter->() ) {
        push @saw, $k, $v;
    }
    cmp_deeply( [@saw], [ $hash->as_list ], "iterator walked hash in order" )
      or diag explain \@saw;

    $iter = $hash->iterator( reverse $hash->keys );
    @saw  = ();
    while ( my ( $k, $v ) = $iter->() ) {
        unshift @saw, $k, $v;
    }
    cmp_deeply(
        [@saw],
        [ $hash->as_list ],
        "iterator( reverse keys ) walked hash in expected order"
    ) or diag explain \@saw;
};

subtest "clear" => sub {

    my $hash = new_ok( HO, [ 'a' .. 'f' ], "new('a'..'f')" );

    cmp_deeply( [ $hash->as_list ], [ 'a' .. 'f' ], "as_list returns non-empty list" );
    is( $hash->clear, undef, "clearing hash returns undef" );
    cmp_deeply( [ $hash->as_list ], [], "as_list returns empty list" );
    cmp_deeply( $hash, HO->new, "cleared hash and new empty hash are equal" );

};

subtest "list methods" => sub {

    for my $size ( 10, 1000 ) {

        my @pairs = ( 1 .. $size * 2 );

        my $hash = new_ok( HO, \@pairs );
        $hash->delete(3); # trigger tombstone on large hash
        splice @pairs, 2, 2; # delete '3' and '4'
        my $hsize       = $hash->keys;
        my $vsize       = $hash->values;
        my $actual_size =()= keys %{ $hash->[0] };
        is( $hsize, $actual_size, "keys gives size in scalar context" );
        is( $vsize, $actual_size, "values gives size in scalar context" );

        is( $hash->push( b => 2, c => 3 ), $hsize + 2, "pushing 2 new pairs" );

        cmp_deeply(
            [ $hash->as_list ],
            [ @pairs, b => 2, c => 3 ],
            "hash keys/values correct after pushing new pairs"
        );

        cmp_deeply( [ $hash->pop ], [ c => 3 ], "pop returns last pair" );

        cmp_deeply(
            [ $hash->as_list ],
            [ @pairs, b => 2 ],
            "hash keys/values correct after pop"
        );

        is( $hash->unshift( y => 25, z => 26 ), $hsize + 3, "unshifting 2 pairs" );

        cmp_deeply(
            [ $hash->as_list ],
            [ y => 25, z => 26, @pairs, b => 2 ],
            "hash keys/values correct after unshifting new pairs"
        );

        cmp_deeply( [ $hash->shift ], [ y => 25 ], "shift returns first pair" );

        cmp_deeply(
            [ $hash->as_list ],
            [ z => 26, @pairs, b => 2 ],
            "hash keys/values correct after shifting"
        );

        ok( $hash->push( z => 42 ), "pushing existing key with new value" );

        cmp_deeply(
            [ $hash->as_list ],
            [ @pairs, b => 2, z => 42 ],
            "hash keys/values correct after pushing existing key"
        );

        ok( $hash->unshift( z => 26 ), "unshifting existing key with new value" );

        cmp_deeply(
            [ $hash->as_list ],
            [ z => 26, @pairs, b => 2 ],
            "hash keys/values correct after unshifting existing key"
        );

        ok( $hash->merge( z => 2, c => 3, d => 4 ), "merging key-value pairs" );

        cmp_deeply(
            [ $hash->as_list ],
            [ z => 2, @pairs, b => 2, c => 3, d => 4 ],
            "hash keys/values correct after merging pairs"
        );

        # scalar context pop/shift
        {
            $hash->push( zz => 'aa' );
            my $v = $hash->pop;
            is( $v, 'aa', "scalar pop returns value" );

            $hash->unshift( yy => 'bb' );
            $v = $hash->shift;
            is( $v, 'bb', "scalar shift returns value" );
        }

        # termination checks
        {
            my $clone = $hash->clone;
            1 while my ( $k, $v ) = $clone->pop;
            pass("pop terminates");
        }

        {
            my $clone = $hash->clone;
            1 while my ( $k, $v ) = $clone->shift;
            pass("shift terminates");
        }

    }

    # empty hash tests
    {
        my $hash = new_ok(HO);

        my ( $k, $v );

        ( $k, $v ) = $hash->pop;
        cmp_deeply( [ $k, $v ], [ undef, undef ], "pop empty in list context" );

        ( $k, $v ) = $hash->shift;
        cmp_deeply( [ $k, $v ], [ undef, undef ], "shift empty in list context" );

        $v = $hash->pop;
        is( $v, undef, "pop empty in scalar context" );

        $v = $hash->shift;
        is( $v, undef, "shift empty in scalar context" );
    }

};

subtest "modifiers" => sub {

    my $hash = new_ok( HO, [ 'a' => 0 ] );

    # preinc
    is( $hash->preinc('a'), 1, "preinc return" );

    # add

    is( $hash->add( 'a', 2 ),  3, "add +2 return" );
    is( $hash->add( 'a', -1 ), 2, "add -1 return" );

    # postinc

    is( $hash->postinc('a'), '2', "postinc return" );
    is( $hash->get('a'),     3,   "value was incremented" );

    # predec

    is( $hash->predec('a'), '2', "predec return" );

    # postdec

    is( $hash->postdec('a'), '2', "postdec return" );
    is( $hash->get('a'),     1,   "value was decremented" );

    # concat

    is( $hash->concat('a'), '1', "concat undef return" );
    is( $hash->concat( 'a', 'a' ), '1a', "concat 'a' return" );

    # or_equals
    is( $hash->or_equals( 'a', 42 ), '1a', "or_equals on existing key" );
    is( $hash->or_equals( 'b', 0 ),  '0',  "or_equals on new key" );
    is( $hash->or_equals( 'b', 42 ), '42', "or_equals on existing, false key" );

    # dor_equals
    is( $hash->dor_equals( 'a', 23 ), '1a', "dor_equals on existing key" );
    is( $hash->dor_equals( 'c', 0 ),  '0',  "dor_equals on new key" );
    is( $hash->dor_equals( 'c', 42 ), '0',  "dor_equals on existing, false key" );
};

subtest 'key ordering' => sub {

    my $hash = new_ok( HO, [] );

    cmp_deeply(
        [ $hash->keys ],
        [],
        'New hash has no keys'
    );

    my $rc = $hash->set( 'Rogers' => 'Captain America' );
    is( $rc, 'Captain America', 'Proper return value' );
    cmp_deeply(
        [ $hash->keys ],
        [ 'Rogers' ],
        'Added Rogers'
    );
    cmp_deeply(
        [ $hash->values ],
        [ 'Captain America' ],
        'Added Rogers'
    );

    # Try to replace an existing entry with or_equals.
    $rc = $hash->or_equals( 'Rogers' => 'Human Torch' );
    is( $rc, 'Captain America', 'Rogers is still Captain America' );

    # Try to replace an existing entry with dor_equals.
    $rc = $hash->dor_equals( 'Rogers' => 'The Impossible Man' );
    is( $rc, 'Captain America', 'Rogers is *still* Captain America' );

    $rc = $hash->or_equals( 'Banner' => 'Hulk' );
    is( $rc, 'Hulk', 'Proper return value' );
    cmp_deeply(
        [ $hash->keys ],
        [ 'Rogers', 'Banner' ],
        'Added Banner through or_equals'
    );
    cmp_deeply(
        [ $hash->values ],
        [ 'Captain America', 'Hulk' ],
        'Added Banner through or_equals'
    );

    $rc = $hash->dor_equals( 'Romanoff' => 'Black Widow' );
    is( $rc, 'Black Widow', 'Proper return value' );
    cmp_deeply(
        [ $hash->keys ],
        [ 'Rogers', 'Banner', 'Romanoff' ],
        'Added Romanoff through or_equals'
    );
    cmp_deeply(
        [ $hash->values ],
        [ 'Captain America', 'Hulk', 'Black Widow' ],
        'Added Romanoff through or_equals'
    );

    # In Captain America #180, Rogers becomes Nomad.
    # Replace him with a call to push().
    $rc = $hash->push( 'Rogers' => 'Nomad' );
    is( $rc, 3, 'There are still three keys' );
    cmp_deeply(
        [ $hash->keys ],
        [ 'Banner', 'Romanoff', 'Rogers' ],
        'Changing Rogers puts him at the end of the list'
    );
    cmp_deeply(
        [ $hash->values ],
        [ 'Hulk', 'Black Widow', 'Nomad' ],
        'Changing Rogers puts him at the end of the list'
    );


};


done_testing;
exit 0;
