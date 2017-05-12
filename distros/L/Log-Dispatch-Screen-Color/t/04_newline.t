use strict;
use warnings;
use Test::More tests => 2;

use IO::Scalar;
use Term::ANSIColor;
use Log::Dispatch::Screen::Color;


captured_is(
    sub {
        my $log = Log::Dispatch::Screen::Color->new(
            name      => 'test',
            min_level => 'debug',
            stderr    => 0,
            color     => { debug => {} },
            newline   => 0,
        );
        $log->log( level => 'debug', message => 'debug' );
    },
    "debug",
);

captured_is(
    sub {
        my $log = Log::Dispatch::Screen::Color->new(
            name      => 'test',
            min_level => 'debug',
            stderr    => 0,
            color     => { debug => {} },
            newline   => 1,
        );
        $log->log( level => 'debug', message => 'debug' );
    },
    "debug\n",
);

sub captured_is {
    my ($code, $expected) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $out = capture( $code );
    is $out, $expected;
}

sub capture {
    my $cb = shift;
    tie *STDOUT, 'IO::Scalar', \my $out;
    $cb->();
    untie *STDOUT;
    $out;
}

