#!perl
use 5.006;
use open qw(:locale);
use strict;
use warnings;
#use utf8;

use lib qw(../lib/);

use Benchmark qw(:all) ;

use LCS::BV;
use LCS;
use Algorithm::Diff;
use Algorithm::Diff::XS;

my @data = (
  [split(//,'Chrerrplzon')],
  [split(//,'Choerephon')]
);

my @strings = qw(Chrerrplzon Choerephon);

my @data2 = (
  [split(//,'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY')],
  [split(//, 'bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')]
);

my @strings2 = qw(
abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY
bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
);

my @data3 = ([qw/a b d/ x 50], [qw/b a d c/ x 50]);

my @strings3 = map { join('',@$_) } @data3;


print "\n",'LCS: Algorithm::Diff, Algorithm::Diff::XS, LCS, LCS::BV',"\n","\n";

print 'LCS: [Chrerrplzon] [Choerephon]',"\n","\n";

if (1) {
    timethese( 50_000, {
        'AD:LCSidx___' => sub {
            Algorithm::Diff::LCSidx(@data)
        },
        'AD:XS:LCSidx' => sub {
            Algorithm::Diff::XS::LCSidx(@data)
        },
        'LCS:BV:LCS__' => sub {
            LCS::BV->LCS(@data)
        },
        'LCS:LCS_____' => sub {
            LCS::->LCS(@data)
        },
    });
}

print "\n",'LCS: [qw/a b d/ x 50], [qw/b a d c/ x 50]',"\n","\n";

if (1) {
    timethese( 3_000, {
        'AD:LCSidx___' => sub {
            Algorithm::Diff::LCSidx(@data3)
        },
        'AD:XS:LCSidx' => sub {
            Algorithm::Diff::XS::LCSidx(@data3)
        },
        'LCS:BV:LCS__' => sub {
            LCS::BV->LCS(@data3)
        },
        'LCS:LCS_____' => sub {
            LCS::->LCS(@data3)
        },
    });
}

print "\n",'LLCS: [Chrerrplzon] [Choerephon]',"\n","\n";

if (1) {
    timethese( 30_000, {
        'AD:LCS_length___' => sub {
            Algorithm::Diff::LCS_length(@data)
        },
        'AD:XS:LCS_length' => sub {
            Algorithm::Diff::XS::LCS_length(@data)
        },
        'LCS:BV:LLCS_____' => sub {
            LCS::BV->LLCS(@data)
        },
        'LCS:LLCS________' => sub {
            LCS->LLCS(@data)
        },
    });
}

print "\n",'LLCS: [qw/a b d/ x 50], [qw/b a d c/ x 50]',"\n","\n";

if (1) {
    timethese( 2_000, {
        'AD:LCS_length___' => sub {
            Algorithm::Diff::LCS_length(@data3)
        },
        'AD:XS:LCS_length' => sub {
            Algorithm::Diff::XS::LCS_length(@data3)
        },
        'LCS:BV:LLCS_____' => sub {
            LCS::BV->LLCS(@data3)
        },
        'LCS:LLCS________' => sub {
            LCS->LLCS(@data3)
        },
    });
}

=pod

LCS-BV/xt$ perl 50_diff_time.t
LCS: Algorithm::Diff, Algorithm::Diff::XS, LCS, LCS::BV

LCS: [Chrerrplzon] [Choerephon]

Benchmark: timing 50000 iterations of AD:LCSidx___, AD:XS:LCSidx, LCS:BV:LCS__, LCS:LCS_____...
AD:LCSidx___:  2 wallclock secs ( 1.61 usr +  0.01 sys =  1.62 CPU) @ 30864.20/s (n=50000)
AD:XS:LCSidx:  1 wallclock secs ( 0.74 usr +  0.00 sys =  0.74 CPU) @ 67567.57/s (n=50000)
LCS:BV:LCS__:  1 wallclock secs ( 0.71 usr +  0.00 sys =  0.71 CPU) @ 70422.54/s (n=50000)
LCS:LCS_____:  5 wallclock secs ( 5.39 usr +  0.00 sys =  5.39 CPU) @ 9276.44/s (n=50000)

LCS: [qw/a b d/ x 50], [qw/b a d c/ x 50]

Benchmark: timing 3000 iterations of AD:LCSidx___, AD:XS:LCSidx, LCS:BV:LCS__, LCS:LCS_____...
AD:LCSidx___: 39 wallclock secs (38.98 usr +  0.01 sys = 38.99 CPU) @ 76.94/s (n=3000)
AD:XS:LCSidx:  1 wallclock secs ( 0.74 usr +  0.00 sys =  0.74 CPU) @ 4054.05/s (n=3000)
LCS:BV:LCS__:  2 wallclock secs ( 2.62 usr +  0.00 sys =  2.62 CPU) @ 1145.04/s (n=3000)
LCS:LCS_____: 64 wallclock secs (63.28 usr +  0.01 sys = 63.29 CPU) @ 47.40/s (n=3000)

LLCS: [Chrerrplzon] [Choerephon]

Benchmark: timing 30000 iterations of AD:LCS_length___, AD:XS:LCS_length, LCS:BV:LLCS_____, LCS:LLCS________...
AD:LCS_length___:  1 wallclock secs ( 0.84 usr +  0.00 sys =  0.84 CPU) @ 35714.29/s (n=30000)
AD:XS:LCS_length:  0 wallclock secs ( 0.82 usr +  0.00 sys =  0.82 CPU) @ 36585.37/s (n=30000)
LCS:BV:LLCS_____:  1 wallclock secs ( 0.22 usr +  0.00 sys =  0.22 CPU) @ 136363.64/s (n=30000)
            (warning: too few iterations for a reliable count)
LCS:LLCS________:  2 wallclock secs ( 2.75 usr +  0.00 sys =  2.75 CPU) @ 10909.09/s (n=30000)

LLCS: [qw/a b d/ x 50], [qw/b a d c/ x 50]

Benchmark: timing 2000 iterations of AD:LCS_length___, AD:XS:LCS_length, LCS:BV:LLCS_____, LCS:LLCS________...
AD:LCS_length___: 26 wallclock secs (25.96 usr +  0.00 sys = 25.96 CPU) @ 77.04/s (n=2000)
AD:XS:LCS_length: 26 wallclock secs (25.94 usr +  0.00 sys = 25.94 CPU) @ 77.10/s (n=2000)
LCS:BV:LLCS_____:  1 wallclock secs ( 0.97 usr +  0.00 sys =  0.97 CPU) @ 2061.86/s (n=2000)
LCS:LLCS________: 42 wallclock secs (41.64 usr +  0.01 sys = 41.65 CPU) @ 48.02/s (n=2000)

=cut

