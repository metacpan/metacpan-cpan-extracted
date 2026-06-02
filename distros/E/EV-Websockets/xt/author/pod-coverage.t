use strict;
use warnings;
use Test::More;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

# Author test: every public method is documented. Run with `prove -lb xt/`.
eval "use Test::Pod::Coverage 1.08; 1"
    or plan skip_all => "Test::Pod::Coverage 1.08 required";
eval "use Pod::Coverage 0.18; 1"
    or plan skip_all => "Pod::Coverage 0.18 required";

use EV::Websockets;

# All three packages live in the single lib/EV/Websockets.pm; satisfy require()
# for the sub-packages and point Pod::Coverage at that one POD file.
$INC{'EV/Websockets/Context.pm'}    ||= __FILE__;
$INC{'EV/Websockets/Connection.pm'} ||= __FILE__;

my @pkgs = qw(
    EV::Websockets
    EV::Websockets::Context
    EV::Websockets::Connection
);

plan tests => scalar @pkgs;

for my $pkg (@pkgs) {
    pod_coverage_ok(
        $pkg,
        {
            pod_from     => 'lib/EV/Websockets.pm',
            also_private => [ qr/^(?:BOOT|DESTROY)$/ ],
            trustme      => [ qr/^(?:import|unimport|bootstrap)$/ ],
        },
        "POD coverage for $pkg",
    );
}
