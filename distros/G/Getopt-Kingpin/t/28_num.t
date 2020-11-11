use strict;
use Test::More 0.98;
use Test::Exception;
use Capture::Tiny ':all';
use Getopt::Kingpin;


subtest 'num normal' => sub {
    local @ARGV;
    push @ARGV, qw(--x 0);

    my $kingpin = Getopt::Kingpin->new;
    my $x = $kingpin->flag('x', 'set x')->num();
    $kingpin->parse;

    is $x->value, 0;
    ok $x == 0;
};

subtest 'num scientific notation 1' => sub {
    local @ARGV;
    push @ARGV, qw(--x 1e3);

    my $kingpin = Getopt::Kingpin->new;
    my $x = $kingpin->flag('x', 'set x')->num();
    $kingpin->parse;

    is $x->value + 0, 1000; # + 0 to force == instead of eq check
    ok $x == 1000;
};

subtest 'num scientific notation 2' => sub {
    local @ARGV;
    push @ARGV, qw(--x -1.5e6);

    my $kingpin = Getopt::Kingpin->new;
    my $x = $kingpin->flag('x', 'set x')->num();
    $kingpin->parse;

    is $x->value + 0, -1_500_000;
    ok $x == -1_500_000;
};

subtest 'num error' => sub {
    local @ARGV;
    push @ARGV, qw(--x ZERO);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $x = $kingpin->flag('x', 'set x')->num();
    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/num parse error/, 'num parse error';
    is $exit, 1;

};

done_testing;

