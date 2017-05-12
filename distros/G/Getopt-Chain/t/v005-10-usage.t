use strict;
use warnings;

use Test::Most;

use Getopt::Chain;

plan qw/no_plan/;

my ($options, @path);

my $run = sub {
    my $context = shift;
    push @path, $context->command;
};

my %process = (
    options => [ qw/apple/ ],
    run => sub {
        $run->(@_);
        my $context = shift;
    },
    commands => {

        grape => {
            options => [ qw/banana:s/ ],
            run => sub {
                $run->(@_);
                my $context = shift;
            },
        },

        mango => {
            run => sub {
                $run->(@_);
                my $context = shift;
            },
        },
    },
);

local @ARGV = qw/--apple mango/;
undef @path;
$options = Getopt::Chain->process(%process);
cmp_deeply($options, { qw/apple 1/ });
cmp_deeply(\@path, [ undef, qw/mango/ ]);

local @ARGV = qw/grape --banana ripe/;
undef @path;
$options = Getopt::Chain->process(%process);
cmp_deeply($options, { qw/banana ripe/ });
cmp_deeply(\@path, [ undef, qw/grape/ ]);

local @ARGV = qw/--apple grape --banana ripe/;
undef @path;
$options = Getopt::Chain->process(%process);
cmp_deeply($options, { qw/apple 1 banana ripe/ });
cmp_deeply(\@path, [ undef, qw/grape/ ]);
