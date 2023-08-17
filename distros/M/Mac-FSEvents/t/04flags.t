use strict;
use warnings;

use Cwd qw( getcwd abs_path );
use File::Path qw( make_path );
use File::Spec;
use File::Temp;
use IO::Select;
use Mac::FSEvents;

use Test::More;

my %capable_of;
foreach my $constant ( qw{ IGNORE_SELF FILE_EVENTS } ) {
    if ( Mac::FSEvents->can( $constant ) ) {
        $capable_of{$constant} = 1;
    }
}

my $TEST_LATENCY = 0.5;
my $TIMEOUT      = 1;

sub touch_file {
    my ( $filename ) = @_;

    my $fh;
    open $fh, '>', $filename or die $!;
    close $fh;

    return;
}

sub fetch_events {
    my ( $fs, $fh ) = @_;

    my @events;

    my $sel = IO::Select->new($fh);

    while ( $sel->can_read( $TIMEOUT ) ) {
        foreach my $event ( $fs->read_events ) {
            push @events, $event;
        }
    }

    return @events;
}

subtest 'none' => sub {
    my $tmpdir = File::Temp->newdir;
    my $tmp_abs = abs_path( "$tmpdir" );

    my $fs = Mac::FSEvents->new({
        path    => "$tmpdir",
        latency => $TEST_LATENCY,
        flags   => 0,
    });

    my $fh = $fs->watch;

    touch_file "$tmpdir/foo.txt";
    touch_file "$tmpdir/bar.txt";

    my @events = fetch_events($fs, $fh);
    is scalar(@events), 2;
    like $events[0]->path, qr/^\Q$tmp_abs/;
};

subtest 'watch_root' => sub {
    my $tmpdir = File::Temp->newdir;
    my $tmp_abs = abs_path( "$tmpdir" );

    my $watch_root = File::Spec->catdir( "$tmpdir", 'foo', 'bar' );
    make_path( $watch_root );
    my $new_root = File::Spec->catdir( "$tmpdir", 'foo', 'baz' );

    my $fs = Mac::FSEvents->new({
        path    => $watch_root,
        latency => $TEST_LATENCY,
        watch_root => 1,
    });

    my $fh = $fs->watch;

    rename $watch_root, $new_root or die $!;

    my @events = fetch_events($fs, $fh);

    is scalar(@events), 1;
    ok $events[0]->root_changed;
};

subtest 'ignore_self' => sub {
    if ( !$capable_of{ IGNORE_SELF } ) {
        pass q{Your platform doesn't support IGNORE_SELF};
        return;
    }

    my $tmpdir = File::Temp->newdir;
    my $tmp_abs = abs_path( "$tmpdir" );
    my $fs = Mac::FSEvents->new({
        path    => "$tmpdir",
        latency => $TEST_LATENCY,
        ignore_self => 1,
    });

    my $fh = $fs->watch;

    # One event from our process
    mkdir "$tmpdir/foo";
    # One event from another process
    system "touch $tmpdir/foo/bar.txt";

    my @events = fetch_events($fs, $fh);

    is scalar(@events), 1;
    like $events[0]->path, qr{^\Q$tmp_abs/foo}, 'got event from other process';
};

subtest 'file_events' => sub {
    if ( !$capable_of{ FILE_EVENTS } ) {
        pass q{Your platform doesn't support FILE_EVENTS};
        return;
    }

    my $tmpdir = File::Temp->newdir;
    my $tmp_abs = abs_path( "$tmpdir" );
    sleep 2; # Wait for the directory to clear the pending events
    my $fs = Mac::FSEvents->new({
        path    => "$tmpdir",
        latency => $TEST_LATENCY,
        file_events => 1,
    });

    my $fh = $fs->watch;

    touch_file( "$tmpdir/foo.txt" );
    touch_file( "$tmpdir/bar.txt" );

    my @events = fetch_events($fs, $fh);

    is scalar @events, 2;
    like $events[0]->path, qr{^\Q$tmp_abs/foo.txt};
    like $events[1]->path, qr{^\Q$tmp_abs/bar.txt};
};

done_testing;
