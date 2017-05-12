#!/usr/bin/perl
use strict;
use warnings;

use lib 'lib';
use Carp qw(confess);
use Benchmark qw(cmpthese);
use Math::Expression::Evaluator;
use Data::Dumper;

my $statement = '2 + a + 5 + (3+4)';
my $iterations = $ARGV[0] || 200;

sub with_optimize {
    my $m = Math::Expression::Evaluator->new($statement);
    $m->optimize;
    for (1..$iterations){
        $m->val({a => $_});
    }
}

sub no_optimize {
    my $m = Math::Expression::Evaluator->new($statement);
    for (1..$iterations){
        $m->val({a => $_});
    }
}

sub compiled {
    my $m = Math::Expression::Evaluator->new($statement);
    my $c = $m->compiled();
    for (1..$iterations){
        $c->({a => $_});
    }
}

sub opt_compiled {
    my $m = Math::Expression::Evaluator->new($statement);
    $m->optimize();
    my $c = $m->compiled();
    for (1..$iterations){
        $c->({a => $_});
    }
}


my %tests = (
        optimize       => \&with_optimize,
        no_optimize    => \&no_optimize,
        compiled       => \&compiled,
        opt_compiled   => \&opt_compiled,
);
#for (100,1000,10000){
#    print $_, "\n";
#    $tests{'opt ' . $_} = sub { with_optimize($_) };
#    $tests{'noopt ' . $_} = sub { no_optimize($_) };
#}

cmpthese(-2, \%tests);


# vim: expandtab
