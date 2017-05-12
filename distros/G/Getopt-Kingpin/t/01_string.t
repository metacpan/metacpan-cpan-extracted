use strict;
use Test::More 0.98;
use Getopt::Kingpin;


subtest 'string normal' => sub {
    local @ARGV;
    push @ARGV, qw(--name kingpin);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->flag('name', 'set name')->string();
    $kingpin->parse;

    is $kingpin->flags->get('name'), 'kingpin';
};

subtest 'string normal 2 options' => sub {
    local @ARGV;
    push @ARGV, qw(--name kingpin --xyz abcde);

    my $k = Getopt::Kingpin->new;
    $k->flag('name', 'option 1')->string;
    $k->flag('xyz',  'option 2')->string;
    $k->parse;

    is $k->flags->get('name'), 'kingpin';
    is $k->flags->get('xyz'), 'abcde';

};


done_testing;

