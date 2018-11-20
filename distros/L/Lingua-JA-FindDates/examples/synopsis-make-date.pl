#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Lingua::JA::FindDates 'subsjdate';

binmode STDOUT, ":utf8";

# A routine can be used to format the date any way, letting C<subsjdate>
# print it:

sub my_date
{
    my ($data, $original, $date) = @_;
    return join '/', $date->{month}."/".$date->{date};
}
my $dates = '三月１６日';
print subsjdate ($dates, {make_date => \&my_date}), "\n";
