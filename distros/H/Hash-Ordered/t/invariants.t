use 5.006;
use strict;
use warnings;
use Test::More 0.96;
##use Test::FailWarnings;
use Test::Deep '!blessed';
use Test::Fatal;
binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

use Hash::Ordered;
use List::Util qw/max min shuffle/;

use constant HO => "Hash::Ordered";

my $thresh = Hash::Ordered::_INDEX_THRESHOLD();

sub _invar {
    my ( $hash, $label ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $label => sub {

        my $err = 0;

        my ( $data, $keys, $indx, $offs, $gcnt ) = @$hash;

        cmp_deeply(
            [ sort grep !ref($_), @$keys ],
            [ sort keys %$data ],
            "all keys in _DATA are in _KEYS"
        ) or $err++;

        my $tomb_cnt = scalar( grep ref($_), @$keys );
        my $non_tomb_cnt = @$keys - $tomb_cnt;

        is( @$keys - $gcnt,
            $non_tomb_cnt,
            "_KEYS length minus _GCNT equals number of non-tombstone keys in _KEYS" )
          or $err++;

        if (%$data) {
            ok( !ref( $keys->[0] ),  "first element of _KEYS is not tombstone" ) or $err++;
            ok( !ref( $keys->[-1] ), "last element of _KEYS is not tombstone" )  or $err++;
        }

        # if indexing has kicked in, invariants change
        if ($indx) {
            pass("has _INDX");

            # find unindexed on right
            my $on_right = 0;
            for my $i ( reverse 0 .. $#{$keys} ) {
                last if !ref( $keys->[$i] );
                $on_right++;
            }

            ok( $gcnt <= @$keys / 2, "no more than half keys elements are tombstones" )
              or $err++;

            is( max( values %$indx ) + $offs + $on_right,
                $#{$keys}, "max index value plus offset plus right-side-unindexed" )
              or $err++;

            cmp_deeply(
                [ sort grep !ref($_), @$keys ],
                [ sort keys %$indx ],
                "all keys in _INDX are in _KEYS"
            ) or $err++;

            cmp_deeply(
                [ sort keys %$data ],
                [ sort keys %$indx ],
                "all keys in _DATA are in _INDX"
            ) or $err++;

            my $mis_indexed = grep { ref($_) } map { $keys->[ $_ + $offs ] } values %$indx;
            is( $mis_indexed, 0, "_INDX elements are all valid" ) or $err++;

        }
        else {
            pass("does not have _INDX");
            is( $offs, 0, "_OFFS is zero without _INDX set" ) or $err++;
            is( $gcnt, 0, "_GCNT is zero without _INDX set" ) or $err++;
        }

        diag explain $hash if $err;
    };

}

sub _new {
    my $size = shift;
    return $size ? HO->new( map { ( $_ => $_ ) } 0 .. $size - 1 ) : HO->new;
}

for my $size ( 0, int( $thresh / 3 ), $thresh + 1, 3 * $thresh ) {
    my ( $k, $v, @pairs );

    my $l = "size $size";

    # construct new hash,
    my $h = _new($size);
    _invar( $h, "$l: after creation" );

    # delete some keys
    my @keys = shuffle $h->keys;
    my @sorted = sort { $a <=> $b } @keys;

    for ( 1 .. 3 ) {
        last unless @keys;
        $h->delete( shift(@keys) );
        _invar( $h, "$l: deleted a key" );
    }

    # clear and recreate
    $h->clear;
    _invar( $h, "$l: after clear" );
    $h = _new($size);
    _invar( $h, "$l: after creation" );

    next unless $size;

    # pop and push
    ( $k, $v ) = $h->pop;
    _invar( $h, "$l: after pop" );
    $h->push( $k, $v );
    _invar( $h, "$l: after push" );

    # shift and unshift
    ( $k, $v ) = $h->shift;
    _invar( $h, "$l: after shift" );
    $h->unshift( $k, $v );
    _invar( $h, "$l: after unshift" );

    # create tombstones at front
    $h->delete(1);
    $h->delete(2);
    _invar( $h, "$l: tombstones at key positions 1 & 2" );
    $h->delete(0);
    _invar( $h, "$l: tombstones at key positions 0" );
    $h->unshift( map { $_ => $_ } 0 .. 3 );
    _invar( $h, "$l: keys 1, 2, 3 unshifted" );

    # create tombstones at back
    $h->delete( $size - 3 );
    $h->delete( $size - 2 );
    _invar( $h, "$l: tombstones at key positions -3 & -2" );
    $h->delete( $size - 1 );
    _invar( $h, "$l: tombstones at key positions -1" );
    $h->push( map { $_ => $_ } $size - 3 .. $size - 1 );
    _invar( $h, "$l: keys from -3, -2, and -1 pushed back " );

    # unshift and delete
    $h->unshift( "a", "b" );
    _invar( $h, "$l: unshift value" );
    $h->delete("a");
    _invar( $h, "$l: delete unshifted value" );

    # push and delete
    $h->push( "a", "b" );
    _invar( $h, "$l: push value" );
    $h->delete("a");
    _invar( $h, "$l: delete pushed value" );

    # set a reference
    $h->push( $h, 42 );
    _invar( $h, "$l: pushed a reference" );
    $h->delete($h);
    _invar( $h, "$l: deleted a reference" );

    # delete remaining keys randomly
    $h->delete($_) for @keys;
    _invar( $h, "$l: remaining keys deleted" );

    # set/delete all keys
    $h->clear;
    $h->set( $_ => -$_ ) for @keys;
    _invar( $h, "$l: set all keys" );
    $h->delete($_) for @keys;
    _invar( $h, "$l: delete all keys" );

    # double set
    $h->clear;
    $h->set( $_ => $_ ) for @sorted;
    $h->set( $_ => $_ ) for @sorted;
    _invar( $h, "$l: double set" );

    # double merge
    $h->clear;
    $h->set( $_ => $_ ) for @keys;
    $h->set( $_ => $_ ) for @keys;
    _invar( $h, "$l: double merge" );

    # double push
    $h->clear;
    $h->push( $_ => $_ ) for @sorted;
    $h->push( $_ => $_ ) for @sorted;
    _invar( $h, "$l: double push" );

    # double unshift
    $h->clear;
    $h->unshift( $_ => $_ ) for @keys;
    $h->unshift( $_ => $_ ) for @keys;
    _invar( $h, "$l: double unshift" );

}

{
    # construct hash with a reference
    my $ref = [];
    my $h = HO->new( $ref, 42 );
    _invar( $h, "construct hash with reference as key" );
    my $j = $h->clone($ref);
    _invar( $j, "clone hash with reference as key" );
}

done_testing;
