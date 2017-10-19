#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Lingua::JA::FindDates 'subsjdate';
binmode STDOUT, ":utf8";
sub mymakedate
{
    my ($data, $original, $date) = @_;
    return qw{Bad Mo Tu We Th Fr Sa Su}[$date->{wday}]. " " .
    $date->{year}.'/'.$date->{month}.'/'.$date->{date};
} 
my $input = '昭和３４年１月１７日（土）。平成9年12月20日（土）。';
my $output = subsjdate ($input, {make_date => \& mymakedate});
print "$output\n";
