#!/usr/bin/perl

use strict;
use warnings;

use Log::Any qw ($log);
use Test::More tests => 2;

use Log::Any::Adapter;

my $is_debug = $ENV{PERL5_DEBUG};

subtest 'Duperr' => \&test_fh, 'STDERR', 'Duperr';
subtest 'Dupout' => \&test_fh, 'STDOUT', 'Dupout';

sub test_fh {
    my ( $std, $adapter ) = @_;

    plan tests => 8;

    no strict 'refs';

    my $std_fh = \*$std;

    diag_fh_detail($std_fh) if $is_debug;

    ok( my @std_stat = $std_fh->stat, "Get stat for $std" );

    ok( Log::Any::Adapter->set($adapter), "Set adapter $adapter" );

    # irresponsible penetration into the object
    my $adapter_fh = $log->{adapter}->{fh};

    diag_fh_detail($adapter_fh) if $is_debug;

    ok( my @adapter_stat_1 = $adapter_fh->stat(), "Get stat for $adapter" );

    is( $adapter_stat_1[1], $std_stat[1], "Inode $std == $adapter after set adapter $adapter" );

    ok( close $std_fh, "Close $std" );

    diag_fh_detail($adapter_fh) if $is_debug;

    ok( my @adapter_stat_2 = $adapter_fh->stat, "Get stat for $adapter" );

    is( $adapter_stat_2[1], $std_stat[1], "Inode $std == $adapter after close $std" );

    # Restore STD*
    ok(open $std_fh, '>&', $adapter_fh);

    diag_fh_detail($std_fh) if $is_debug;
}

sub diag_fh_detail {
    my ($fh) = @_;

    my $fd = fileno $fh;

    # non-portable (only Linux, tested on Mint)
    my $fn = readlink "/proc/self/fd/$fd";

    diag(qq{fh = "$fh"});
    diag(qq{fd = "$fd"});
    diag(qq{fn = "$fn"});

    return;
}
