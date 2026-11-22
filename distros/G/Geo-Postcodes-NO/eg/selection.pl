#!/usr/bin/perl
use strict;
use warnings;
use Geo::Postcodes::NO;

unless (@ARGV == 2)
{
    print "Usage: selection.pl <field> <value>\n";
    print "Legal fields: ", join(" ", Geo::Postcodes::NO::get_fields()), ".\n";
    exit;
}

my $field = shift(@ARGV);
my $value = shift(@ARGV);
my @fields;

if (Geo::Postcodes::NO::is_field($field))
{
    @fields = Geo::Postcodes::NO::get_fields();
    foreach my $m (@fields)
    {
        printf("%-14s", ucfirst($m));
    }
    print "\n";

    Geo::Postcodes::NO->selection_loop(\&print_it, $field, $value);
    print "\n";
}
else # illegal field.
{
    print "Not a legal field '$field'.\n";
}

sub print_it
{
    my $object = shift;
    foreach my $method (@fields)
    {
        printf("%-14s", $object->$method() || "");
    }
    print "\n";
}