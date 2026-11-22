#!/usr/bin/perl
use strict;
use warnings;
use Geo::Postcodes::NO;

unless (@ARGV)
{
    print "Usage: basic.pl <one or more postcodes>\n";
    exit;
}

foreach my $postcode (@ARGV)
{
    if (my $P = Geo::Postcodes::NO->new($postcode))
    {
        foreach my $field (Geo::Postcodes::NO::get_fields())
        {
            printf("%-10s\t%s\n", ucfirst($field), $P->$field() || "");
        }
        printf("%-10s\t%s\n\n", "Type_en",
            Geo::Postcodes::NO::type2verbose_english($P->type()));
    }
    else
    {
        if (Geo::Postcodes::NO::legal($postcode))
        {
            print "Postcode '$postcode' not in use.\n\n";
        }
        else
        {
            print "Illegal postcode '$postcode'.\n\n";
        }
    }
}