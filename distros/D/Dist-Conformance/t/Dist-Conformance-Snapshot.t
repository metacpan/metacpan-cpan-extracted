#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;

use Dist::Conformance::Snapshot();

# A minimal subclass: the base class builds everything else on paths().
package Fake::Snapshot {
    use Mojo::Base 'Dist::Conformance::Snapshot', -signatures;
    sub paths ($) { return { 'a/b/c' => 'sha-c', 'a/d' => 'sha-d', 'ab' => 'sha-ab', 'e' => 'sha-e' } }
}

subtest blob_sha => sub {
    is( Dist::Conformance::Snapshot::blob_sha(q{}),       'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391', 'the empty blob has the SHA that git gives it' );
    is( Dist::Conformance::Snapshot::blob_sha("hello\n"), 'ce013625030ba8dba906f756967f9e9ca394464a', 'a one-line blob has the SHA that git hash-object prints' );
};

subtest 'paths and content are abstract' => sub {
    my $bare = Dist::Conformance::Snapshot->new;
    like( dies { $bare->paths },        qr/does\ not\ implement\ paths/,   'paths dies in the base class' );
    like( dies { $bare->content('x') }, qr/does\ not\ implement\ content/, 'content dies in the base class' );
};

subtest contains => sub {
    my $snapshot = Fake::Snapshot->new;
    ok( $snapshot->contains('a/d'),   'a listed path is there' );
    ok( !$snapshot->contains('a'),    'a directory is not a path' );
    ok( !$snapshot->contains('nope'), 'an unlisted path is not there' );
};

subtest sha => sub {
    my $snapshot = Fake::Snapshot->new;
    is( $snapshot->sha('e'),    'sha-e', 'the SHA of a listed path' );
    is( $snapshot->sha('nope'), undef,   'no SHA for an unlisted path' );
};

subtest under => sub {
    my $snapshot = Fake::Snapshot->new;
    is( [ $snapshot->under('a') ], [ 'b/c', 'd' ], 'every depth below the directory, relative and sorted, and not the sibling ab' );
    is( [ $snapshot->under('z') ], [],             'nothing under a directory that is not there' );
};

subtest writable => sub {
    ok( !Fake::Snapshot->new->writable, 'a snapshot is read-only unless it says otherwise' );
};

done_testing;
