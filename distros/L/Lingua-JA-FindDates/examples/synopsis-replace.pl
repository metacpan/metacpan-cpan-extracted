#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Lingua::JA::FindDates 'subsjdate';

binmode STDOUT, ":utf8";

# subsjdate can call back when a date is found:

sub replace_callback
{
    my ($data, $before, $after) = @_;
    print "'$before' was replaced by '$after'.\n";
}
my $date = '三月１６日';
subsjdate ($date, {replace => \&replace_callback});

