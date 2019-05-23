use strict;
use warnings;
use Test::More;
use Time::HiRes 'usleep';
use Guard::Timer;

my $duration;
do {
    my $x = timer_guard { $duration = shift } 3;
    usleep 1000;
};

like(
    $duration,
    qr/^0\.\d{3}$/,
    'the guard should be called, with the formatted elapsed time',
);

done_testing;
