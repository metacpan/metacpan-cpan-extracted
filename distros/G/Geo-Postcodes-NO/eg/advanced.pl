#!/usr/bin/perl
use strict;
use warnings;
use Geo::Postcodes::NO;
use Digest::SHA;

my @arg1 = ('postcode' => '(..)\1');
print "All postcodes where the first two digits are repeated:\n";
my @postcodes = Geo::Postcodes::NO::selection(@arg1);
print join(", ", @postcodes), ".\n\n";

print "As above, but with the addition of a procedure:\n";
my @arg2 = (@arg1, 'procedure' => \&selector_procedure);
@postcodes = Geo::Postcodes::NO::selection(@arg2);
print join(", ", @postcodes), ".\n\n";

sub selector_procedure
{
    my $postcode = shift;
    my $location = Geo::Postcodes::NO::location_of($postcode);
    my $digest   = Digest::SHA::sha1_hex($location);
    return 1 if substr($digest, 10, 5) =~ /[a-f]/;
    return 0;
}