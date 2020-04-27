use strict;
use Test::More 0.98;
use Test::Exception;
use Capture::Tiny ':all';
use Getopt::Kingpin;


subtest 'short option' => sub {
    local @ARGV;
    push @ARGV, qw(-n kingpin);

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->short('n')->required->string();

    $kingpin->parse;

    is $name, 'kingpin';
};

subtest 'short and long option' => sub {
    local @ARGV;
    push @ARGV, qw(-n kingpin --xxxx 3);

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->short('n')->required->string();
    my $xxxx = $kingpin->flag('xxxx', 'set xxxx')->required->string();

    $kingpin->parse;

    is $name, 'kingpin';
    is $xxxx, 3;
};

subtest 'unknown short flag' => sub {
    local @ARGV;
    push @ARGV, qw(-h);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/error: unknown short flag '-h', try --help/;
    is $exit, 1;
};

subtest 'POSIX-style short flag combining 1' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $x = $kingpin->flag("long_x", "")->short("x")->bool();
    my $y = $kingpin->flag("long_y", "")->short("y")->bool();

    $kingpin->parse;

    is $x, 0;
    is $y, 0;
};

subtest 'POSIX-style short flag combining 2' => sub {
    local @ARGV;
    push @ARGV, qw(-xy);

    my $kingpin = Getopt::Kingpin->new;
    my $x = $kingpin->flag("long_x", "")->short("x")->bool();
    my $y = $kingpin->flag("long_y", "")->short("y")->bool();

    $kingpin->parse;

    is $x, 1;
    is $y, 1;
};

subtest 'Short-flag+parameter combining 1' => sub {
    local @ARGV;
    push @ARGV, qw(-x 12);

    my $kingpin = Getopt::Kingpin->new;
    my $x = $kingpin->flag("long_x", "")->short("x")->int();

    $kingpin->parse;

    is $x, 12;
};

subtest 'Short-flag+parameter combining 2' => sub {
    local @ARGV;
    push @ARGV, qw(-x12);

    my $kingpin = Getopt::Kingpin->new;
    my $x = $kingpin->flag("long_x", "")->short("x")->int();

    $kingpin->parse;

    is $x, 12;
};

subtest 'Short-flag+parameter combining 3' => sub {
    local @ARGV;
    push @ARGV, qw(-yx12);

    my $kingpin = Getopt::Kingpin->new;
    my $x = $kingpin->flag("long_x", "")->short("x")->int();
    my $y = $kingpin->flag("long_y", "")->short("y")->bool();

    $kingpin->parse;

    is $x, 12;
    is $y, 1;
};

subtest 'Short-flag+parameter combining 4 error' => sub {
    local @ARGV;
    push @ARGV, qw(-x12y);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $x = $kingpin->flag("long_x", "")->short("x")->int();
    my $y = $kingpin->flag("long_y", "")->short("y")->bool();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/int parse error/;
    is $exit, 1;
};

done_testing;

