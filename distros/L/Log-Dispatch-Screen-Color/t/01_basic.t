use strict;
use warnings;
use Test::More tests => 11;

use IO::Scalar;
use Term::ANSIColor;
use Log::Dispatch::Screen::Color;

my @levels = qw( debug info notice warning err error crit critical alert emerg emergency );

my $color = {};
for my $level (@levels) {
    $color->{$level} = {
        text       => 'red',
        background => 'white',
    };
}

my $log = Log::Dispatch::Screen::Color->new(
    name      => 'test',
    min_level => 'debug',
    stderr    => 0,
    color     => $color,
);

for my $level (@levels) {
    my $out = capture(
        sub {
            $log->log( level => $level, message => $level );
        }
    );
    diag($out);
    is($out,
       color('on_white') . color('red') . $level . color('reset') . color('reset'),
       "log method with $level"
    );
}


sub capture {
    my $cb = shift;
    tie *STDOUT, 'IO::Scalar', \my $out;
    $cb->();
    untie *STDOUT;
    $out;
}
