use strict;
use Test::More 0.98;
use Capture::Tiny ':all';
use Getopt::Kingpin;


subtest 'invalid flag' => sub {
    local @ARGV;
    push @ARGV, qw(--verbose);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/error: unknown long flag '--verbose', try --help/, 'invalid flag';
    is $exit, 1;
};

subtest 'invalid flag 2' => sub {
    local @ARGV;
    push @ARGV, qw(-v);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/error: unknown short flag '-v', try --help/, 'invalid flag';
    is $exit, 1;
};

done_testing;

