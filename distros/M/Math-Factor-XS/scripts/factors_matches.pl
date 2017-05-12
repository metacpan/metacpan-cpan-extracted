#!/usr/bin/perl

use strict;
use warnings;

use Math::Factor::XS ':all';

my $number = 30107;

{
    my @factors = factors($number);
    my @matches = matches($number, \@factors);

    show_factors(\@factors);
    show_matches(\@matches);
}

sub _header
{
    my ($title) = @_;

    my $draw_line = sub { return \($_[0] x length $_[1]) };

    return <<EOT;
${$draw_line->('=', $title)}
$title
${$draw_line->('=', $title)}

$number
${$draw_line->('-', $number)}

EOT
}

sub show_factors
{
    my ($factors) = @_;

    print _header('factors');

    local $, = "\t";
    print "@$factors\n\n";
}

sub show_matches
{
    my ($matches) = @_;

    print _header('matches');

    foreach my $i (0 .. $#$matches) {
        printf("%-5d * %d\n", $matches->[$i][0], $matches->[$i][1]);
    }
    print "\n";
}
