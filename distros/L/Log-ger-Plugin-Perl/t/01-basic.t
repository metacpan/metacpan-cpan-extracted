#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;
use Test::Warn;

use Log::ger::Util;

# XXX test default action

subtest "opt:action" => sub {
    require Log::ger::Output;
    Log::ger::Output->set('Perl', action => {
        trace => 'warn',
        debug => 'die',
        info  => 'carp',
        warn  => 'cluck',
        error => 'croak',
        fatal => 'confess',
    });
    my $h = {}; Log::ger::init_target(hash => $h);
    warning_like { $h->{trace}("m1") } qr/m1/;
    throws_ok    { $h->{debug}("m2") } qr/m2/;
    warning_like { $h->{info} ("m3") } qr/m3/;
    warning_like { $h->{warn} ("m4") } qr/m4/;
    throws_ok    { $h->{error}("m5") } qr/m5/;
    throws_ok    { $h->{fatal}("m6") } qr/m6/;
};

done_testing;
