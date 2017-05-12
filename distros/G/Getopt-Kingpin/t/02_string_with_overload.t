use strict;
use Test::More 0.98;
use Getopt::Kingpin;


subtest 'string normal with overload' => sub {
    local @ARGV;
    push @ARGV, qw(--name kingpin);

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->string();
    $kingpin->parse;

    is $name, 'kingpin';
};


done_testing;

