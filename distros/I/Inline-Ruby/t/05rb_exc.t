#!/usr/bin/perl -w

use Test::More tests => 8;

use strict;
use Data::Dumper;
use Inline::Ruby qw(rb_eval);

# TEST:$n=2;
sub e {
    my ($str, $exc) = @_;
    eval { rb_eval($str) };
    return unless $@;
    my $x = $@;

    my $inspect = sprintf("#<%s: %s>", $x->type, $x->message);

    # TEST*$n
    # Methods:
    like ($x->message, $exc->[0], 'Message is right');
    # TODO : Apparently you cannot mix and match prints with
    # evaling ruby code, so we need to find a way to fix it. Meanwhile,
    # I am commenting-out the prints.
    # print Dumper $x->message;

    # TEST*$n
    is ($x->type, $exc->[1], 'Type is right');
    # print Dumper $x->type;

    # TEST*$n
    is ($x->inspect, $inspect, 'Inspect is right');
    # print Dumper $x->inspect;

    # Stringification:
    # TEST*$n
    is ("$x", "$inspect\n", 'Stringification');
    # print "Stringified: '$x'\n";

    # Backtrace (not tested)
    # print Dumper $x->backtrace;

    return;
}

# div by zero
e(  "1/0",
    [qr/divided by 0/, 'ZeroDivisionError']
);

# parse error
e(  "1/",
    [qr/(?:compile error)|(?:syntax error, unexpected \$end)/, 'SyntaxError'],
);
