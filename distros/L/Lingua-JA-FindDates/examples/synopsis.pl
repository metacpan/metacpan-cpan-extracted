#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;

binmode STDOUT, ":utf8";

# Find and replace Japanese dates:

use Lingua::JA::FindDates 'subsjdate';

# Given a string, find and substitute all the Japanese dates in it.

my $dates = '昭和４１年三月１６日';
print subsjdate ($dates), "\n";

# Find and substitute Japanese dates within a string:

$dates = 'blah blah blah 三月１６日';
print subsjdate ($dates), "\n";

# subsjdate can also call back a user-supplied routine each time a
# date is found:

sub replace_callback
{
    my ($data, $before, $after) = @_;
    print "'$before' was replaced by '$after'.\n";
}
$dates = '三月１６日';
my $data = 'xyz';	       # something to send to replace_callback
subsjdate ($dates, {replace => \&replace_callback, data => $data});

# A routine can be used to format the date any way, letting C<subsjdate>
# print it:

sub my_date
{
    my ($data, $original, $date) = @_;
    return join '/', $date->{month}."/".$date->{date};
}
$dates = '三月１６日';
print subsjdate ($dates, {make_date => \&my_date}), "\n";

# Convert Western to Japanese dates
use Lingua::JA::FindDates 'seireki_to_nengo';
print seireki_to_nengo ('1989年1月1日'), "\n";
