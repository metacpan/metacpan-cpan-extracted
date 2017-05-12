use strict;
use Test::More 0.98;
use Test::Trap;
use Getopt::Kingpin;


subtest 'invalid flag' => sub {
    local @ARGV;
    push @ARGV, qw(--verbose);

    my $kingpin = Getopt::Kingpin->new;

    trap {
        $kingpin->parse;
    };

    like $trap->stderr, qr/error: unknown long flag '--verbose', try --help/, 'invalid flag';
    is $trap->exit, 1;
};

subtest 'invalid flag 2' => sub {
    local @ARGV;
    push @ARGV, qw(-v);

    my $kingpin = Getopt::Kingpin->new;

    trap {
        $kingpin->parse;
    };

    like $trap->stderr, qr/error: unknown short flag '-v', try --help/, 'invalid flag';
    is $trap->exit, 1;
};

done_testing;

