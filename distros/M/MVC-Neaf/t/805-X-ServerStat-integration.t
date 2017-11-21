#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;
use MVC::Neaf::X::ServerStat;
my @trace;

my $stat = MVC::Neaf::X::ServerStat->new(
    write_thresh_count => 1,
    on_write => sub { push @trace, @{ +shift } },
);

MVC::Neaf->route( '/foo' => sub { +{} }, -view => 'JS' );
MVC::Neaf->server_stat( $stat );

my @warn;
$SIG{__WARN__} = sub { push @warn, shift };

my @res = MVC::Neaf->run_test( '/foo' );

is (scalar @trace, 1, "Stat recorded");
note explain $trace[0];

is ($trace[0][0], '/foo', "URI");
is ($trace[0][1], 200, "Status");

like ($trace[0][$_], qr/\d+(?:\.\d+)?/, "Time in $_")
    for (2..4);

is (scalar @warn, 0, "no warnings issued" );
diag "WARN: $_" for @warn;
done_testing;
