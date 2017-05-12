#!/usr/bin/env perl
use warnings;
use strict;
use Benchmark qw(cmpthese timethese :hireswallclock);
use Try::Tiny;
use Error::Return;

cmpthese(timethese(500_000, {
    manual => sub {
        my $return;
        try { die 'Foo' } catch { $return++ };
        return if $return;
    },
    RETURN => sub {
        try { die 'Foo' } catch { RETURN };
    },
}));

sub normal { return }
sub special { RETURN }

sub call_normal { normal () }
sub call_special { special() }

cmpthese(timethese(10_000_000, {
    manual => sub { call_normal() },
    RETURN => sub { call_special() },
}));


__END__

Benchmark: timing 500000 iterations of RETURN, manual...
    RETURN: 6.84833 wallclock secs ( 6.58 usr +  0.03 sys =  6.61 CPU) @ 75642.97/s (n=500000)
    manual: 6.35331 wallclock secs ( 6.31 usr +  0.01 sys =  6.32 CPU) @ 79113.92/s (n=500000)
          Rate RETURN manual
RETURN 75643/s     --    -4%
manual 79114/s     5%     --

Benchmark: timing 10000000 iterations of RETURN, manual...
    RETURN: 23.4454 wallclock secs (23.34 usr +  0.03 sys = 23.37 CPU) @ 427899.02/s (n=10000000)
    manual: 3.0584 wallclock secs ( 3.02 usr +  0.01 sys =  3.03 CPU) @ 3300330.03/s (n=10000000)
            Rate RETURN manual
RETURN  427899/s     --   -87%
manual 3300330/s   671%     --

