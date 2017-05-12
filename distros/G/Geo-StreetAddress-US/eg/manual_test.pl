#!/usr/bin/perl 

use Geo::StreetAddress::US;
use Term::ReadLine;
use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);
use strict;
use warnings;

my $term = new Term::ReadLine 'Geo::StreetAddress::US';
my $prompt = "> ";
my $OUT = $term->OUT || \*STDOUT;

print $OUT <<End;
Geo::StreetAddress::US ver. $Geo::StreetAddress::US::VERSION command line interface!
Enter a US address or intersection.
End

while ( defined ($_ = $term->readline($prompt)) ) {
    my $t0  = [gettimeofday];
    my $res = Geo::StreetAddress::US->parse_location($_);
    my $interval = tv_interval($t0);
    warn $@ if $@;
    unless ($@) {
	print $OUT Dumper($res), "\n";
	printf $OUT "(Query took %.3f seconds)\n", $interval;
    }
    $term->addhistory($_) if /\S/;
}

