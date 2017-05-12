#!/usr/bin/perl -w

use strict;
use warnings;
use List::Util qw/sum/;
use Test::More;
use Test::Warnings;
use Getopt::Alt;
use Data::Dumper qw/Dumper/;

my $opt = Getopt::Alt->new(
    {
        bundle => 1,
    },
    [
        'plain|p',
        'inc|i+',
        'negate|n!',
        'string|s=s',
        'integer|I=i',
        'float|f=f',
        'value|v=[yes|auto|no]',
        'count|c++',
    ],
);

for my $argv ( argv() ) {
    eval { $opt->process( @{ $argv } ) };
    ok( $@, join ' ', @{ $argv }, 'fails') or diag Dumper $opt->opt;
}
done_testing();

sub argv {
    return (
        [ qw/--incclude / ],
        [ qw/-r         / ],
        [ qw/--string   / ],
        [ qw/-I   negate/ ],
        [ qw/-I 12negate/ ],
        [ qw/-f 2.3a    / ],
        [ qw/-v any     / ],
    );
}

