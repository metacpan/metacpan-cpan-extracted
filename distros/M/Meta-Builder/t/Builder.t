#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Lite;

our $CLASS;
BEGIN {
    $CLASS = 'Meta::Builder';
    require_ok $CLASS;
}

{
    package MyMeta;
    use Meta::Builder;
    use Fennec::Lite;

    isa_ok( __PACKAGE__, "Meta::Builder::Base" );

    can_ok( __PACKAGE__, qw/
        metric action before after add_metric add_action hook_before hook_after
        accessor new make_immutable add_lists_metric add_hash_metric
        lists_metric hash_metric
    / );

    accessor 'mymeta';
    metric mymetric => sub { [] },
           pop => sub {
               my $self = shift;
               my ( $data ) = @_;
               pop @$data;
           };
    action mymetric => push => sub {
        my $self = shift;
        my ( $data, $metric, $action, @args ) = @_;
        push @$data => @args;
    };

    hash_metric 'myhash';
    lists_metric 'mylists';

    # These actions should all have been added
    can_ok( __PACKAGE__, qw/
        mymetric myhash mylists
        mymetric_pop mymetric_push
        myhash_add myhash_clear myhash_get myhash_has myhash_pull
        mylists_push mylists_clear mylists_get mylists_has mylists_pull
    /);
}

my $meta = MyMeta->new( __PACKAGE__ );

tests meta_applied => sub {
    is( $meta, mymeta(), "Got meta" );
    is( $meta->package, __PACKAGE__, "Meta applied to correct package" );
};

tests mymetric => sub {
    isa_ok( $meta->mymetric, 'ARRAY' );
    is_deeply( $meta->mymetric, [], "mymetric empty" );
    $meta->mymetric_push( 'a', 'b' );
    is_deeply( $meta->mymetric, [qw/a b/], "mymetric filled" );
    is( $meta->mymetric_pop(), 'b', "popped mymetric" );
    is_deeply( $meta->mymetric, ['a'], "mymetric altered" );
};

tests myhash => sub {
    isa_ok( $meta->myhash, 'HASH' );
    is_deeply( $meta->myhash, {}, "myhash empty" );

    $meta->myhash_add( 'a', 'b' );
    is_deeply( $meta->myhash, { a => 'b' }, "myhash filled" );
    is( $meta->myhash_get('a'), 'b', "got from myhash" );
    ok( $meta->myhash_has( 'a' ), "have 'a'" );
    ok( !$meta->myhash_has( 'b' ), "don't have 'b'" );

    $meta->myhash_add( 'c', 'd' );
    $meta->myhash_clear( 'a' );
    is_deeply( $meta->myhash, { c => 'd' }, "myhash filled" );

    $meta->myhash_add( 'a', 'b' );
    is_deeply( $meta->myhash_pull( 'a' ), 'b', "pulled" );
    is_deeply( $meta->myhash, { c => 'd' }, "myhash filled" );
};

tests mylists => sub {
    isa_ok( $meta->mylists, 'HASH' );
    is_deeply( $meta->mylists, {}, "mylists empty" );

    $meta->mylists_push( 'a', 'b', 'c', 'd' );
    is_deeply( $meta->mylists, { a => [qw/b c d/] }, "mylists filled" );
    is_deeply( [$meta->mylists_get('a')], [qw/b c d/], "got from mylists" );
    ok( $meta->mylists_has( 'a' ), "have 'a'" );
    ok( !$meta->mylists_has( 'b' ), "don't have 'b'" );

    $meta->mylists_push( 'c', 'd', 'e', 'f' );
    $meta->mylists_clear( 'a' );
    is_deeply( $meta->mylists, { c => [qw/d e f/] }, "mylists filled" );

    $meta->mylists_push( 'a', 'b' );
    is_deeply( [$meta->mylists_pull( 'a' )], ['b'], "pulled" );
    is_deeply( $meta->mylists, { c => [qw/d e f/] }, "mylists filled" );
};

tests external_adding => sub {
    MyMeta->add_metric( 'a' );
    MyMeta->add_action( 'a', 'do', sub {} );
    MyMeta->add_hash_metric( 'b' );
    MyMeta->add_lists_metric( 'c' );
    can_ok( 'MyMeta', qw/
        a b c
        a_do
        b_add b_clear b_get b_has b_pull
        c_push c_clear c_get c_has c_pull
    /);
};

run_tests();

tests hooks => sub {
    MyMeta->hook_before( 'mylists', 'push', sub {
        my $self = shift;
        my ( $data, $metric, $action, $key, @values ) = @_;
        die "can't add values to list 'x'"
            if $key eq 'x';
    });
    MyMeta->hook_after( 'mylists', 'push', sub {
        my $self = shift;
        my ( $data, $metric, $action, $key, @values ) = @_;
        die "can't add values to list 'y'"
            if $key eq 'y';
    });

    ok( ! $meta->mylists_has( 'x' ), "No 'x'" );
    throws_ok { $meta->mylists_push( x => 'a' ) }
        qr/can't add values to list 'x'/,
        "before hook was triggered";
    ok( ! $meta->mylists_has( 'x' ), "triggered before push" );

    ok( ! $meta->mylists_has( 'y' ), "No 'y'" );
    throws_ok { $meta->mylists_push( y => 'a' ) }
        qr/can't add values to list 'y'/,
        "after hook was triggered";
    ok( $meta->mylists_has( 'y' ), "triggered after push" );
};

run_tests();

tests immutibility => sub {
    MyMeta->make_immutable;
    throws_ok { MyMeta->$_ }
        qr/MyMeta has been made immutable, cannot call '$_'/,
        "$_ cannot be called when immutable"
        for qw/ metric action before after add_metric add_action hook_before
            hook_after accessor make_immutable add_lists_metric add_hash_metric
            lists_metric hash_metric /;
};

run_tests();
done_testing;
