#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use GitHub::MergeVelocity::Repository::PullRequest;

{
    my $created = DateTime->now->subtract( days => 10 );
    my $pr = GitHub::MergeVelocity::Repository::PullRequest->new(
        created_at => $created,
        number     => 99,
        title      => 'Foo',
    );

    is( $pr->state, 'open', 'is open' );
    ok( !$pr->is_work_in_progress, 'not a WIP' );

    # allow for funkiness if tests run around midnight GMT
    ok( ( $pr->age == 10 || $pr->age == 11 ), 'age checks out' );
    ok( !$pr->velocity, 'has no velocity' );
}

{
    my $pr = GitHub::MergeVelocity::Repository::PullRequest->new(
        created_at => '2010-01-01',
        merged_at  => '2011-06-01',
        number     => 99,
        title      => 'Foo',
    );

    is( $pr->state, 'merged', 'is merged' );
    is( $pr->age,   516,      'age' );
    ok( $pr->velocity < 0, 'has negative velocity: ' . $pr->velocity );
}

{
    my $pr = GitHub::MergeVelocity::Repository::PullRequest->new(
        created_at => '2010-01-01',
        merged_at  => '2010-01-02',
        number     => 99,
        title      => 'Shiver my timbers',
    );

    ok( $pr->velocity > 0, 'has positive velocity: ' . $pr->velocity );
}

{
    foreach my $title ( '[WIP] foo', 'WIP: foo' ) {
        my $pr = GitHub::MergeVelocity::Repository::PullRequest->new(
            created_at => '2010-01-01',
            merged_at  => '2010-01-01',
            number     => 99,
            title      => $title,
        );

        is( $pr->age,      0, 'age is 0' );
        is( $pr->velocity, 0, 'zero velocity for WIPs' );
        ok( $pr->is_work_in_progress, 'WIP' );
    }
}

{
    my $start = DateTime->new( year => 2010, month => 1, day => 1 );
    foreach my $days ( 0 .. 60 ) {
        my $pr = GitHub::MergeVelocity::Repository::PullRequest->new(
            created_at => $start,
            merged_at  => $start->clone->add( days => $days ),
            number     => 99,
            title      => 'Foo',
        );

        #        diag 'age: ' . $pr->age;
        #        diag 'velocity: ' . $pr->velocity;
    }
}

done_testing;

