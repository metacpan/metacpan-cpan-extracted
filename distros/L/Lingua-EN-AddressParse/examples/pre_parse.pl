#!/usr/local/bin/perl

# /examples/pre_parse.pl
# Demo script for Lingua::EN::AddressParse.pm

use strict;
use Lingua::EN::AddressParse;


my %args =
(
   country     => 'Australia',
   auto_clean  => 1,
   force_case  => 1,
);


my $address = Lingua::EN::AddressParse->new(%args);

while (<DATA>)
{
    chomp($_);
    my $input = correct($_);
	my $error = $address->parse($input);

    print("-" x 50,"\n", $address->report);
}

#------------------------------------------------------------------------------
# Correct common typing errors to make address more well formed
sub correct
{
    my ($address) = @_;

    # Fix badly formed   abbreviations
    $address =~ s|CSEWY|CAUSEWAY|;
    $address =~ s|Csewy|Causeway|;
    $address =~ s|LVL|LEVEL|;
    $address =~ s|Lvl|Level|;


    # Fix badly formed number dividers sush as 14/ 12, 2- 7A
    $address =~ s|/ |/|;
    $address =~ s| /|/|;
    $address =~ s|- |-|;
    $address =~ s| -|/|;
    $address =~ s|,| |;

    return($address);
}


__DATA__
LVL 2 12 Moore Park Road WODIN NSW 2600
SHED 23/12 A STREET WODIN NSW 2600 AUSTRALIA
23B/ 14C SOUTH HEAD ROAD WODIN NSW 2600 AUSTRALIA
PO BOX 222 FINLEY NEW SOUTH WALES 2713
U12 2 SMITH ST ULTIMO NSW 2007
