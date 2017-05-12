#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use FindBin qw($Bin);
use Test::More tests => 60;

$Data::Dumper::Indent = 0;
$Data::Dumper::Terse  = 1;

$ENV{LOG_DECLARE_NO_STARTUP_NOTICE} = 1;

sub is_enabled {
    my ($level, $expected_levels) = @_;

    local $ENV{LOG_DECLARE_STARTUP_LEVEL} = $level;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    # my $stderr = capture_stderr { system { $^X } ($^X, "$Bin/levels.pl") };
    my $stderr = qx{ $^X "$Bin/levels.pl" 2>&1 }; # XXX use Capture::Tiny
    my @stderr = split $/, $stderr;

    is shift(@stderr), 'START';
    is pop(@stderr),   'END';

    # all of the levels >= the current level (may be empty)
    # e.g. for INFO: [ 'info', 'warn', 'error', 'audit' ]
    my $enabled_levels = [ map { /(\w+)$/ } @stderr ];

    # level errors are easier to diagnose with strings than with arrayrefs/is_deeply
    is (
        join(', ', @$enabled_levels),
        join(', ', @$expected_levels),
        sprintf('enabled log levels for %s: %s', Dumper($level), Dumper($expected_levels))
    );
}

is_enabled undef, [ qw(error audit) ];
is_enabled '', [ qw(error audit) ];

is_enabled invalid => [ qw(trace debug info warn error audit) ];
is_enabled INVALID => [ qw(trace debug info warn error audit) ];

is_enabled trace => [ qw(trace debug info warn error audit) ];
is_enabled TRACE => [ qw(trace debug info warn error audit) ];

is_enabled debug => [ qw(debug info warn error audit) ];
is_enabled DEBUG => [ qw(debug info warn error audit) ];

is_enabled info => [ qw(info warn error audit) ];
is_enabled INFO => [ qw(info warn error audit) ];

is_enabled warn => [ qw(warn error audit) ];
is_enabled WARN => [ qw(warn error audit) ];

is_enabled error => [ qw(error audit) ];
is_enabled ERROR => [ qw(error audit) ];

is_enabled audit => [ qw(audit) ];
is_enabled AUDIT => [ qw(audit) ];

is_enabled off => [];
is_enabled OFF => [];

is_enabled disable => [];
is_enabled DISABLE => [];
