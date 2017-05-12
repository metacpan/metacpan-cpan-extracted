use strict;
use Test::More 0.98;
use Getopt::Kingpin;


subtest 'double dash' => sub {
    local @ARGV;
    push @ARGV, qw(--name kingpin -- path);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->flag("bbb", "")->string();
    $kingpin->flag("ccc", "")->string();
    $kingpin->flag("aaa", "")->string();
    $kingpin->flag("eee", "")->string();
    $kingpin->flag("ddd", "")->string();

    my @keys = $kingpin->flags->keys;
    is +(scalar @keys), 6;
    is $keys[0], "help";
    is $keys[1], "bbb";
    is $keys[2], "ccc";
    is $keys[3], "aaa";
    is $keys[4], "eee";
    is $keys[5], "ddd";

};

done_testing;

