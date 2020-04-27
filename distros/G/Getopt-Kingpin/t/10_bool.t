use strict;
use Test::More 0.98;
use Capture::Tiny ':all';
use Getopt::Kingpin;


subtest 'bool' => sub {
    local @ARGV;
    push @ARGV, qw(--verbose);

    my $kingpin = Getopt::Kingpin->new;
    my $x = $kingpin->flag('verbose', 'set verbose mode')->bool();
    $kingpin->parse;

    ok $x;
    is $x, 1;
};

subtest 'bool negative' => sub {
    local @ARGV;
    push @ARGV, qw(--no-verbose);

    my $kingpin = Getopt::Kingpin->new;
    my $x = $kingpin->flag('verbose', 'set verbose mode')->bool();
    $kingpin->parse;

    ok not $x;
    is $x, 0;
};

subtest 'bool default' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $x = $kingpin->flag('verbose', 'set verbose mode')->default(1)->bool();
    $kingpin->parse;

    ok $x;
    is $x, 1;
};

subtest 'bool default 2' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $x = $kingpin->flag('verbose', 'set verbose mode')->default(0)->bool();
    $kingpin->parse;

    ok not $x;
    is $x, 0;
};

subtest 'bool required' => sub {
    local @ARGV;
    push @ARGV, qw(--verbose);

    my $kingpin = Getopt::Kingpin->new;
    my $x = $kingpin->flag('verbose', 'set verbose mode')->required()->bool();
    $kingpin->parse;

    ok $x;
    is $x, 1;
};

subtest 'bool required 2' => sub {
    local @ARGV;
    push @ARGV, qw(--no-verbose);

    my $kingpin = Getopt::Kingpin->new;
    my $x = $kingpin->flag('verbose', 'set verbose mode')->required()->bool();
    $kingpin->parse;

    ok not $x;
    is $x, 0;
};

subtest 'bool required 3' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $x = $kingpin->flag('verbose', 'set verbose mode')->required()->bool();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/error: required flag --verbose not provided, try --help/, 'required error';

};

done_testing;

