use strict;
use Test::More 0.98;
use Capture::Tiny ':all';
use Getopt::Kingpin;


subtest 'required' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    $kingpin->flag('name', 'set name')->required->string();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/error: required flag --name not provided, try --help/, 'required error';
    is $exit, 1;
};

subtest 'required and not required' => sub {
    local @ARGV;
    push @ARGV, qw(--name abc --x 3);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $name = $kingpin->flag('name', 'set name')->required->string();
    my $x = $kingpin->flag('x', 'set x')->int();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    is $exit, undef;
    is $name, 'abc';
    is $x, 3;
};

done_testing;

