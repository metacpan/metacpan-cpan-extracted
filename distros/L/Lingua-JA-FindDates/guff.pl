#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Lingua::JA::FindDates 'subsjdate';
my $text = '平成3年';
    my $translation = subsjdate ($text, {make_date => \mymakedate,
                                 make_date_interval => \myinterval});

sub mymakedate
{
}
sub myinterval
{
}
