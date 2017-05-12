#!/usr/bin/perl

# Compares random number generation timings for Perl's core function,
# Math::Random::MT::Auto and Math::Random::MT (if available).

# Usage:  timings.pl [--local] [COUNT]
#       --local = Don't try internet sources

use strict;
use warnings;
no warnings 'void';

$| = 1;

use Math::Random::MT::Auto qw(rand irand gaussian exponential
                              srand get_seed set_seed :!auto);
use Time::HiRes;
use Config;

# Warning signal handler
my @WARN;
$SIG{__WARN__} = sub { push(@WARN, @_); };


# Potentially available sources
my %SRCS = (
    '/dev/random' => 1,
    'win32'       => 1,
    'random_org'  => 1,
    'hotbits'     => 1,
    'rn_info'     => 1,
);

# Internet sources
my @INET = qw(random_org hotbits rn_info);

my $DEFAULT_SRC = 'random_org';

MAIN:
{
    # Command line arguments
    my $count = 3120000;
    my $local = 0;
    for my $arg (@ARGV) {
        if ($arg eq '--local') {
            # Local mode - no Internet sources
            $local = 1;
        } else {
            $count = 0 + $arg;
        }
    }

    # Check sources
    check_sources($local);

    my ($cnt, $start, $end);

    print("Random numbers generation timing\n");

    print("\n- Core -\n");

    # Time Perl's srand()
    my $seed = CORE::time() + $$;
    $start = Time::HiRes::time();
    CORE::srand($seed);
    $end = Time::HiRes::time();
    printf("srand:\t\t%f secs.\n", $end - $start);

    # Loop overhead
    $cnt = $count;
    $start = Time::HiRes::time();
    while ($cnt--) {
    }
    $end = Time::HiRes::time();
    my $overhead = $end - $start;

    # Time Perl's rand()
    $cnt = $count;
    $start = Time::HiRes::time();
    while ($cnt--) {
        CORE::rand();
    }
    $end = Time::HiRes::time();
    printf("rand:\t\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

    # Reseed
    CORE::srand($seed);

    # Time Perl's rand(arg)
    $cnt = $count;
    $start = Time::HiRes::time();
    while ($cnt--) {
        CORE::rand(5);
    }
    $end = Time::HiRes::time();
    printf("rand(5):\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

    # Time Perl's rand() to product 64-bit randoms
    if ($Config{'uvsize'} == 8) {
        # Reseed
        CORE::srand($seed);

        $cnt = $count;
        $start = Time::HiRes::time();
        while ($cnt--) {
            (int(CORE::rand(4294967296)) << 32) | int(CORE::rand(4294967296));
        }
        $end = Time::HiRes::time();
        printf("rand [64-bit]:\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);
    }

    my @seed = @{get_seed()};       # Copy of existing seed

    print("\n- Math::Random::MT::Auto - Standalone PRNG -\n");

    # Time our srand()
    while (my ($src, $available) = each(%SRCS)) {
        if ($available) {
            $start = Time::HiRes::time();
            srand($src, $DEFAULT_SRC);
            $end = Time::HiRes::time();
            printf("srand:\t\t%f secs. (%s %s)\n", $end - $start, $src, $DEFAULT_SRC);
            @seed = @{get_seed()};
        }
    }

    # Time our irand()
    $cnt = $count;
    $start = Time::HiRes::time();
    while ($cnt--) {
        irand();
    }
    $end = Time::HiRes::time();
    printf("irand:\t\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

    # Reseed
    set_seed(\@seed);

    # Time our rand()
    $cnt = $count;
    $start = Time::HiRes::time();
    while ($cnt--) {
        rand();
    }
    $end = Time::HiRes::time();
    printf("rand:\t\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

    # Reseed
    set_seed(\@seed);

    # Time our rand(arg)
    $cnt = $count;
    $start = Time::HiRes::time();
    while ($cnt--) {
        rand(5);
    }
    $end = Time::HiRes::time();
    printf("rand(5):\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

    # Reseed
    set_seed(\@seed);

    # Time gaussian()
    $cnt = $count;
    $start = Time::HiRes::time();
    while ($cnt--) {
        gaussian();
    }
    $end = Time::HiRes::time();
    printf("gaussian:\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

    # Reseed
    set_seed(\@seed);

    # Time gaussian(sd, mean)
    $cnt = $count;
    $start = Time::HiRes::time();
    while ($cnt--) {
        gaussian(3, 69);
    }
    $end = Time::HiRes::time();
    printf("gaussian(3,69):\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

    # Reseed
    set_seed(\@seed);

    # Time exponential()
    $cnt = $count;
    $start = Time::HiRes::time();
    while ($cnt--) {
        exponential();
    }
    $end = Time::HiRes::time();
    printf("expon:\t\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

    # Reseed
    set_seed(\@seed);

    # Time exponential(mean)
    $cnt = $count;
    $start = Time::HiRes::time();
    while ($cnt--) {
        exponential(5);
    }
    $end = Time::HiRes::time();
    printf("expon(5):\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

    # Reseed
    set_seed(\@seed);

    print("\n- Math::Random::MT::Auto - OO Interface -\n");

    # Time our ->new()
    my $rand;
    while (my ($src, $available) = each(%SRCS)) {
        if ($available) {
            $start = Time::HiRes::time();
            $rand = Math::Random::MT::Auto->new('SOURCE' => [$src, $DEFAULT_SRC]);
            $end = Time::HiRes::time();
            printf("new:\t\t%f secs. (%s %s)\n", $end - $start, $src, $DEFAULT_SRC);
        }
    }

    # Reseed
    $rand->set_seed(\@seed);

    # Time our irand()
    $cnt = $count;
    $start = Time::HiRes::time();
    while ($cnt--) {
        $rand->irand();
    }
    $end = Time::HiRes::time();
    printf("irand:\t\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

    # Reseed
    $rand->set_seed(\@seed);

    # Time our rand()
    $cnt = $count;
    $start = Time::HiRes::time();
    while ($cnt--) {
        $rand->rand();
    }
    $end = Time::HiRes::time();
    printf("rand:\t\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

    # Reseed
    $rand->set_seed(\@seed);

    # Time our rand(arg)
    $cnt = $count;
    $start = Time::HiRes::time();
    while ($cnt--) {
        $rand->rand(5);
    }
    $end = Time::HiRes::time();
    printf("rand(5):\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

    # Reseed
    $rand->set_seed(\@seed);

    # Time our gaussian()
    $cnt = $count;
    $start = Time::HiRes::time();
    while ($cnt--) {
        $rand->gaussian();
    }
    $end = Time::HiRes::time();
    printf("gaussian:\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

    # Reseed
    $rand->set_seed(\@seed);

    # Time gaussian(sd, mean)
    $cnt = $count;
    $start = Time::HiRes::time();
    while ($cnt--) {
        $rand->gaussian(3, 69);
    }
    $end = Time::HiRes::time();
    printf("gaussian(3,69):\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

    # Reseed
    $rand->set_seed(\@seed);

    # Time our exponential()
    $cnt = $count;
    $start = Time::HiRes::time();
    while ($cnt--) {
        $rand->exponential();
    }
    $end = Time::HiRes::time();
    printf("expon:\t\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

    # Reseed
    $rand->set_seed(\@seed);

    # Time exponential(mean)
    $cnt = $count;
    $start = Time::HiRes::time();
    while ($cnt--) {
        $rand->exponential(5);
    }
    $end = Time::HiRes::time();
    printf("expon(5):\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

    # Reseed
    $rand->set_seed(\@seed);

    # See if Math::Random::MT is available
    eval { require Math::Random::MT;
           import Math::Random::MT qw(srand rand);
           srand($seed); };
    if (! $@) {
        print("\n- Math::Random::MT - Functional Interface -\n");

        # Time its srand() function
        $start = Time::HiRes::time();
        $rand = srand($seed);
        $end = Time::HiRes::time();
        printf("srand:\t\t%f secs.\n", $end - $start);

        # Time its rand()
        $cnt = $count;
        $start = Time::HiRes::time();
        while ($cnt--) {
            rand();
        }
        $end = Time::HiRes::time();
        printf("rand:\t\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

        # Reseed
        srand($seed);

        # Time its rand(arg)
        $cnt = $count;
        $start = Time::HiRes::time();
        while ($cnt--) {
            rand(5);
        }
        $end = Time::HiRes::time();
        printf("rand(5):\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

        # Time its rand() to product 64-bit randoms
        if ($Config{'uvsize'} == 8) {
            # Reseed
            $rand = Math::Random::MT->new(@seed);

            $cnt = $count;
            $start = Time::HiRes::time();
            while ($cnt--) {
                (int(rand(4294967296)) << 32) | int(rand(4294967296));
            }
            $end = Time::HiRes::time();
            printf("rand [64-bit]:\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);
        }

        print("\n- Math::Random::MT - OO Interface -\n");

        # Time its new(@seed) method
        $start = Time::HiRes::time();
        $rand = Math::Random::MT->new(@seed);
        $end = Time::HiRes::time();
        printf("new:\t\t%f secs. (+ seed acquisition time)\n", $end - $start);

        # Time its rand() method
        $cnt = $count;
        $start = Time::HiRes::time();
        while ($cnt--) {
            $rand->rand();
        }
        $end = Time::HiRes::time();
        printf("rand:\t\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);

        # Reseed
        $rand = Math::Random::MT->new(@seed);

        # Time its rand(arg) method
        $cnt = $count;
        $start = Time::HiRes::time();
        while ($cnt--) {
            $rand->rand(5);
        }
        $end = Time::HiRes::time();
        printf("rand(5):\t%f secs. (%d)\n", ($end-$start)-$overhead, $count);
    }
}

exit(0);


### Subroutines ###

sub check_sources
{
    my $local = $_[0];

    print('Checking seed sources...');

    # Check availability of win32 source
    eval { srand('win32'); };
    if ($@ || @WARN) {
        $SRCS{'win32'} = 0;
        undef(@WARN);
    } else {
        $SRCS{'win32'} = 1;
        $DEFAULT_SRC = 'win32';
    }

   # Check availability of /dev/random source
    if (-e '/dev/random') {
        srand('/dev/random');
        if (@WARN) {
            $SRCS{'/dev/random'} = 0;
            undef(@WARN);
        } else {
            $SRCS{'/dev/random'} = 1;
            $DEFAULT_SRC = '/dev/random';
        }
    } else {
        $SRCS{'/dev/random'} = 0;
    }

    # Local mode - no Internet sources
    if ($local) {
        @SRCS{@INET} = 0;
        return;
    }

    # Check for LWP::UserAgent module
    eval {
        require LWP::UserAgent;
    };
    if ($@) {
        @SRCS{@INET} = 0;
        return;
    }

    # Check availability of Internet sources
    for my $src (@INET) {
        srand($src, $DEFAULT_SRC);
        if (@WARN) {
            $SRCS{$src} = 0;
            undef(@WARN);
        } else {
            $SRCS{$src} = 1;
        }
    }

    # Done
    print("\n\n");
}

# EOF
