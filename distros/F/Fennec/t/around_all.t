#!/usr/bin/perl
use strict;
use warnings;

use Fennec;

my $parent_pid = $$;

describe set => sub {
    my $pid;
    my $count = 0;
    my $count2 = 0;
    my $count3 = 0;

    before_all blah => sub {
        $count2++;
    };

    around_each bar => sub {
        is( $count3, 1, "already 1" );
        $count3++;
    };

    around_all foo => sub {
        my $self = shift;
        my ($run) = @_;
        $count++;
        $pid = $$;

        $count3++;

        $run->();
    };

    for my $i ( 1 .. 10 ) {
        tests $i => sub {
            is( $count, 1, "ran once" );
            is( $count2, 1, "ran once" );
            is( $count3, 2, "both ran" );
            is( $pid, $parent_pid, "ran in parent" );
        };
    }
};

done_testing;
