use strict;
use Test::More 0.98;
use Test::Trap;
use Getopt::Kingpin;


subtest 'required' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->flag('name', 'set name')->required->string();

    trap {
        $kingpin->parse;
    };

    like $trap->stderr, qr/error: required flag --name not provided, try --help/, 'required error';
    is $trap->exit, 1;
};

subtest 'required and not required' => sub {
    local @ARGV;
    push @ARGV, qw(--name abc --x 3);

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->required->string();
    my $x = $kingpin->flag('x', 'set x')->int();

    trap {
        $kingpin->parse;
    };

    is $trap->exit, undef;
    is $name, 'abc';
    is $x, 3;
};

done_testing;

