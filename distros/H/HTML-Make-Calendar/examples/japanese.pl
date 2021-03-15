#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use HTML::Make::Calendar 'calendar';
use Date::Qreki 'rokuyou_unicode';
use Calendar::Japanese::Holiday;
use Lingua::JA::Numbers 'num2ja';
use Lingua::JA::FindDates 'seireki_to_nengo';

binmode STDOUT, ":encoding(utf8)";
my @daynames = (qw!月 火 水 木 金 土 日!);
my $calendar = calendar (daynames => \@daynames,
			 monthc => \&jmonth,
			 dayc => \&jday, first => 7);
print $calendar->text ();
exit;

sub jday
{
    my (undef, $date, $element) = @_;
    my @jdate = ($date->{year}, $date->{month}, $date->{dom});
    my $name = isHoliday (@jdate);
    my $rokuyou = rokuyou_unicode (@jdate);
    $element->push ('span', text => num2ja ($date->{dom}));
    $element->push ('br');
    $element->push ('span', text => $rokuyou, attr => {class => 'rokuyou'});
    if ($name) {
	$element->push ('br');
	$element->push ('b', text => $name);
	$element->add_class ('holiday');
    }
}

sub jmonth
{
    my (undef, $date, $element) = @_;
    my $month = $date->{month} . '月';
    my $year = seireki_to_nengo ("$date->{year}年");
    my $ym = "$year$month";
    $ym =~ s/([0-9]+)/num2ja($1)/ge;
    $element->add_text ($ym);
}
