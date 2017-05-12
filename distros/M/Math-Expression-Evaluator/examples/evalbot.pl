#!/usr/bin/perl
use strict;
use warnings;


# Suppose you want to write an all-purpose IRC bot. One of its cool features
# is that if somebody writes down a mathematic expression, your bot will 
# print the results.
#
# now since you're a very sociable hacker you want to reduce line noise as
# much as possible, which means that your bot won't print error messages if
# something went wrong, and if somebody writes simply a number, your bot
# doesn't just echo it - remember, a number is also a valid expression.

# the IRC bot part can be done very simply with Bot::BasicBot. Here I just
# present the math logic

# for finding the modules even if not installed - not needed if you install
# the module properly (recommended ;-)).
use lib '../lib/';
use lib 'lib';

use Math::Expression::Evaluator;
my $m = Math::Expression::Evaluator->new();

sub my_math_eval {
    my $str = shift;

    # catch any errors:
    my $r = eval {
        $m->parse($str);
        # parse will throw an exception if something went wrong.
        # if we are here, it means that the expression was parsed fine
        
        # now check if the expression worth evaluating at all:
        return if $m->ast_size < 2;

        # and finally do the work:
        return $m->val();
    };
    if ($@){
        # an error occured - return undef:
        return;
    } else {
        return $r;
    }
}

# now test our sub:

my @inputs = (
        'some random test',
        '234',
        '1.234e23',
        '1/0',
        '2+3',
        '2^20',
        '2-2',
);

for (@inputs) {
    my $r = my_math_eval($_);
    if (defined $r){
        print "Input: <$_> produced $r\n";
    } else {
        print "Input <$_> produced no output\n";
    }
}
