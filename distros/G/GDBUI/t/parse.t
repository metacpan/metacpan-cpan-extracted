#!/usr/bin/env perl -Tw

use strict;

use lib 't';
use Parse;

use Test::Simple tests => 0+keys(%Parse::Tests);


use Text::Shellwords::Cursor;

my $parser = new Text::Shellwords::Cursor;
die "No parser" unless $parser;

for my $input (sort keys %Parse::Tests) {
    my($index,$cpos,$test) = $input =~ /^(\d+):(\d*):(.*)$/;
    die "No test in item $index:    $input\n" unless defined $test;

    my($toks, $tokno, $tokoff) = $parser->parse_line($test, messages=>0, cursorpos=>$cpos);
    my $result = [$toks, $tokno, $tokoff];
    ok(0 == cmp_deep($result, $Parse::Tests{$input}), "Test $index");
}


# Tries to return a valid comparison
# If the data types don't match, claims a>b. '

sub cmp_deep
{
    my($a,$b) = @_;
    my $refa = ref $a;
    my $refb = ref $b;

    return 1 if $refa ne $refb;
    if(not $refa) {
        return $a cmp $b if defined($a) && defined($b);
        return 1 if !defined($a) && defined($b);
        return -1 if defined($a) && !defined($b);
        return 0;
    } elsif($refa eq 'SCALAR') {
        return cmp_deep($$a, $$b);
    } elsif($refa eq 'ARRAY') {
        return @$a <=> @$b if @$a <=> @$b;
        for(my $i=0; $i < @$a; $i++) {
            my $res = cmp_deep($a->[$i], $b->[$i]);
            return $res if $res;
        }
    } else {
        die "Can't compare a: $a '$refa'\n";
    }

    return 0;
}
