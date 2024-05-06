use v5.36;
use IO::FD;
use POSIX; 


use Benchmark qw<cmpthese>;

cmpthese -1, {
    iofd=>sub {IO::FD::stat "."},
    perl =>sub {stat "."},
    posix =>sub {POSIX::stat "."}
};

cmpthese -1, {
    iofd=>sub {IO::FD::stat fileno STDIN},
    perl =>sub {stat STDIN},
    posix =>sub {POSIX::stat fileno STDIN}
};
