use strict;
use warnings;

use File::Spec;
use File::Temp;
use Mac::FSEvents;
use Test::More;

BEGIN {
    unless ( Mac::FSEvents->can('FILE_EVENTS') ) {
        plan skip_all => 'OS X 10.7 or greater needed for this test';
        exit 0;
    }
}

my $LATENCY         = 0.5;
my $TIMEOUT         = 120;
my $EXPECTED_EVENTS = 10_000;

sub is_same_file {
    my ( $lhs, $rhs ) = @_;

    my ( $lhs_dev, $lhs_inode ) = (stat $lhs)[0, 1];
    my ( $rhs_dev, $rhs_inode ) = (stat $rhs)[0, 1];

    return $lhs_dev == $rhs_dev && $lhs_inode == $rhs_inode;
}

my $tmpdir = File::Temp->newdir;

sleep 2; # make sure we don't receive an event for creating our tmpdir

subtest 'test that we receive all expected events' => sub {
    my $fsevents = Mac::FSEvents->new({
        path    => "$tmpdir",
        latency => $LATENCY,
        file_events => 1,
    });

    $fsevents->watch;

    my $event_count = 0;

    for my $n ( 1 .. $EXPECTED_EVENTS) {
        File::Temp->new( DIR => "$tmpdir" );
    }

    $SIG{'ALRM'} = sub { die "alarm" };

    alarm $TIMEOUT;

    eval {
        EVENT_LOOP:
        while ( my @events = $fsevents->read_events ) {
            foreach my $e (@events) {
                my $path = $e->path;
                my ( undef, $dir ) = File::Spec->splitpath($path);

                if ( is_same_file( $dir, "$tmpdir" ) ) {
                    $event_count++;
                    last EVENT_LOOP if $event_count >= $EXPECTED_EVENTS;
                }
            }
        }
    };

    if ( $@ && $@ !~ /alarm/ ) {
        die $@;
    }

    is $event_count, $EXPECTED_EVENTS, 'every event should be seen';
};

done_testing;
