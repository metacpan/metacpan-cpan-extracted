#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Lingua::JA::FindDates 'subsjdate';
sub crazy_date
{
    my ($date) = @_;
    my $out = "$date->{month}/$date->{date}";
    if ($date->{year}) {
	$out = "$date->{year}/$out";
    }
    return $out;
}
sub myinterval
{
    my ($data, $original, $date1, $date2) = @_;
    # Ignore C<$data> and C<$original>.
    return crazy_date ($date1) . " until " . crazy_date ($date2);
} 
my $input = '昭和３４年１月１７日〜12月20日。';
binmode STDOUT, ":utf8";
#$Lingua::JA::FindDates::verbose = 1;
my $output = subsjdate ($input, {make_date_interval => \& myinterval});
print "$output\n";
