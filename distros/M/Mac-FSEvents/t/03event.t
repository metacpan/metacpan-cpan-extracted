#!/usr/bin/perl

use strict;

use Cwd qw( abs_path );
use File::Temp;
use IO::Select;
use Mac::FSEvents;
use Scalar::Util qw(reftype);

use Test::More;

my $tmpdir = File::Temp->newdir;
# FSEvents reports the real location, which may not be the same as
# the same as the path the the tempdir has.
my $abs_tmp = abs_path( $tmpdir );

my $since;

subtest 'test a simple event' => sub {
    # Test single argument to constructor is path
    my $fs = Mac::FSEvents->new( $tmpdir->dirname );

    $fs->watch;

    my $tmp = File::Temp->new( DIR => $tmpdir->dirname );
    note "Created file: $tmp";

    eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm 3;

        my $seen_event;
        READ:
        while ( my @events = $fs->read_events ) {
            for my $event ( @events ) {
                my $path = $event->path;
                $since   = $event->id;
                note "Got event for $path";
                if ( $path =~ /^\Q$abs_tmp/ ) {
                    $seen_event = 1;
                    last READ;
                }
            }
        }
        ok( $seen_event, 'event received (poll interface)' );

        alarm 0;
    };

    if ( $@ ) {
        die $@ unless $@ eq "alarm\n";
    }
    ok( ! $@, 'event received (poll interface)' );

    $fs->stop;
};

subtest 'test select interface' => sub {
    my $fs = Mac::FSEvents->new( {
        path    => $tmpdir->dirname,
        latency => 0.5,
    } );

    my $fh = $fs->watch;

    # Make sure it's a real filehandle
    is( reftype($fh), 'GLOB', 'fh is a GLOB' );

    my $tmp = File::Temp->new( DIR => $tmpdir->dirname );
    note "Created file: $tmp";

    eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm 3;

        my $sel = IO::Select->new($fh);

        my $seen_event;
        READ:
        while ( $sel->can_read ) {
            for my $event ( $fs->read_events ) {
                my $path = $event->path;
                note "Got event for $path";
                if ( $path =~ /^\Q$abs_tmp/ ) {
                    $seen_event = 1;
                    last READ;
                }
            }
        }
        ok( $seen_event, 'event received (select interface)' );

        alarm 0;
    };

    if ( $@ ) {
        die $@ unless $@ eq "alarm\n";
    }
    ok( ! $@, 'event received (select interface)' );

    $fs->stop;
};

subtest 'Test since param and that we receive a history_done flag' => sub {
    # Test name/value pairs as constructor
    my $fs = Mac::FSEvents->new(
        path    => $tmpdir->dirname,
        since   => $since,
        latency => 0.5,
    );

    $fs->watch;

    eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm 3;

        my $seen_event;
        READ:
        while ( my @events = $fs->read_events ) {
            for my $event ( @events ) {
                my $path = $event->path;
                note "Got event for $path";
                if ( $event->history_done ) {
                    $seen_event = 1;
                    last READ;
                }
                else {
                    like $path, qr/^\Q$abs_tmp/;
                }
            }
        }
        ok( $seen_event, 'history event received' );

        alarm 0;
    };

    if ( $@ ) {
        die $@ unless $@ eq "alarm\n";
    }
    ok( ! $@, 'history event received' );

    $fs->stop;
};

subtest 'watch multiple paths at once' => sub {
    my $tmpdir = File::Temp->newdir;
    # FSEvents reports the real location, which may not be the same as
    # the same as the path the the tempdir has.
    my $abs_tmp = abs_path( $tmpdir );
    note "Watching: $abs_tmp/foo and $abs_tmp/bar";

    mkdir "$tmpdir/foo";
    mkdir "$tmpdir/bar";

    my $fs = Mac::FSEvents->new(
        path    => [ "$tmpdir/foo", "$tmpdir/bar" ],
        latency => 0.5,
    );

    my $fh = $fs->watch;

    # Make sure it's a real filehandle
    is reftype $fh, 'GLOB', 'watch returns GLOB';

    my $tmp_foo = File::Temp->new( DIR => "$tmpdir/foo" );
    my $tmp_bar = File::Temp->new( DIR => "$tmpdir/bar" );
    note "Created file: $tmp_foo";
    note "Created file: $tmp_bar";

    eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm 3;

        my $sel = IO::Select->new($fh);

        my $seen_event;
        READ:
        while ( $sel->can_read ) {
            for my $event ( $fs->read_events ) {
                my $path = $event->path;
                note "Got event for $path";
                if ( $path =~ m{^\Q$abs_tmp/\E(foo|bar)} ) {
                    $seen_event++;
                    last READ if $seen_event >= 2;
                }
            }
        }
        is $seen_event, 2, 'got all the events we expected';

        alarm 0;
    };

    if ( $@ ) {
        die $@ unless $@ eq "alarm\n";
    }
    ok !$@, 'alarm not reached';

    $fs->stop;
};

done_testing;
