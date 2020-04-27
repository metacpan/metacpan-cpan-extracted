use strict;
use Test::More 0.98;
use Test::Exception;
use Capture::Tiny ':all';
use Getopt::Kingpin;


subtest 'arg' => sub {
    local @ARGV;
    push @ARGV, qw(--name=kingpin arg1 arg2);

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->string();
    my $arg1 = $kingpin->arg('arg1', 'set arg1')->string();
    my $arg2 = $kingpin->arg('arg2', 'set arg2')->string();

    $kingpin->parse;

    is $name, 'kingpin';
    is $arg1, 'arg1';
    is $arg2, 'arg2';
};

subtest 'arg required' => sub {
    local @ARGV;
    push @ARGV, qw(--name=kingpin arg1);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $name = $kingpin->flag('name', 'set name')->string();
    my $arg1 = $kingpin->arg('arg1', 'set arg1')->string();
    my $arg2 = $kingpin->arg('arg2', 'set arg2')->required->string();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/required arg 'arg2' not provided/, 'required error';
    is $exit, 1;
};

subtest 'arg required 2' => sub {
    local @ARGV;
    push @ARGV, qw(--name=kingpin);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $name = $kingpin->flag('name', 'set name')->string();
    my $arg1 = $kingpin->arg('arg1', 'set arg1')->string();
    my $arg2 = $kingpin->arg('arg2', 'set arg2')->required->string();

    # requiredがついている手前は、全てrequiredの扱い
    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    like $stderr, qr/required arg 'arg2' not provided/, 'required error';
    is $exit, 1;
};

subtest 'arg required 3' => sub {
    local @ARGV;
    push @ARGV, qw(--name=kingpin arg1 arg2);

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->string();
    my $arg1 = $kingpin->arg('arg1', 'set arg1')->string();
    my $arg2 = $kingpin->arg('arg2', 'set arg2')->required->string();

    # requiredがついている手前は、全てrequiredの扱い
    lives_ok {
        $kingpin->parse;
    };

    is $arg1, 'arg1';
    is $arg2, 'arg2';
};

subtest 'arg num' => sub {
    local @ARGV;
    push @ARGV, qw(--name=kingpin arg1);

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->string();
    my $arg1 = $kingpin->arg('arg1', 'set arg1')->string();

    $kingpin->parse;

    is $arg1, 'arg1';
};

subtest 'arg get' => sub {
    local @ARGV;
    push @ARGV, qw(arg1);

    my $kingpin = Getopt::Kingpin->new;
    my $arg1 = $kingpin->arg('arg1', 'set arg1')->string();

    $kingpin->parse;

    is $kingpin->args->get_by_index(0), 'arg1';
};

done_testing;

