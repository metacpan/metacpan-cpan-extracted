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

    accessor 'mymeta';
    hash_metric 'myhash';
    lists_metric 'mylists';
}

tests merge => sub {
    my $meta = MyMeta->new( 'FAKEA' );
    my $other = MyMeta->new( 'FAKEB' );

    $meta->myhash_add( 'a' => 'b' );
    $meta->myhash_add( 'b' => 'c' );
    $meta->mylists_push( a => qw/a b c/ );
    $other->myhash_add( 'c' => 'd' );
    $other->myhash_add( 'd' => 'e' );
    $other->mylists_push( a => qw/d e f/ );

    $meta->merge( $other );

    is_deeply(
        $meta->myhash,
        {
            a => 'b',
            b => 'c',
            c => 'd',
            d => 'e',
        },
        "Merged hash",
    );

    is_deeply(
        $meta->mylists,
        { a => [qw/a b c d e f/] },
        "Merged lists",
    );
};

tests fail => sub {
    my $meta = MyMeta->new( 'FAKEC' );
    my $other = MyMeta->new( 'FAKED' );

    $meta->myhash_add( 'a' => 'b' );
    $other->myhash_add( 'a' => 'd' );
    throws_ok { $meta->merge( $other )}
        qr/a is defined for myhash in both meta-objects/,
        "Cannot merge hashes with the same keys";
};

run_tests();
done_testing;
