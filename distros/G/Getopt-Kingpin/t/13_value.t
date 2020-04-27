use strict;
use Test::More 0.98;
use Test::Exception;
use Capture::Tiny ':all';
use Getopt::Kingpin;


subtest 'default type' => sub {
    local @ARGV;
    push @ARGV, qw(--name=kingpin hello);

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name');
    my $word = $kingpin->arg('word', 'set word');

    $kingpin->parse;

    is $name, 'kingpin';
    is $word, 'hello';
};

subtest 'validate value' => sub {
    local @ARGV;
    push @ARGV, qw(--num 10);

    my $kingpin = Getopt::Kingpin->new;
    my $num = $kingpin->flag('num', 'set number')->int();

    $kingpin->parse;

    is $num, 10;
};

subtest 'validate value parse error' => sub {
    local @ARGV;
    push @ARGV, qw(--num ten);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $num = $kingpin->flag('num', 'set number')->int();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/int parse error/, "int parse error";
    is $exit, 1;
};

done_testing;

