#!/usr/bin/perl
use strict;
use warnings;
use Geo::Postcodes::NO;

my ($status, @lines) = Geo::Postcodes::NO::verify_selectionlist(@ARGV);

if ($status == 0)
{
    print "Usage:\n",
          " * multiselection.pl [all|none]\n",
          " * multiselection.pl [",
          join("|", Geo::Postcodes::NO::get_initial_selectionmodes()),
          "]? <field> <value> [[",
          join("|", Geo::Postcodes::NO::get_selectionmodes()),
          "]? [<field> <value>]]*\n\n";
    print "Legal fields: ", join(", ", Geo::Postcodes::NO::get_fields()), "\n\n";
    print "Diagnostic output:\n";
    foreach (@lines)
    {
        print " * $_\n";
    }
    exit;
}

my @fields = Geo::Postcodes::NO::get_fields();
foreach my $m (@fields)
{
    printf("%-14s", ucfirst($m));
}
print "\n";

foreach my $P (Geo::Postcodes::NO->selection(@lines))
{
    foreach my $method (@fields)
    {
        printf("%-14s", $P->$method() || "");
    }
    print "\n";
}
print "\n";