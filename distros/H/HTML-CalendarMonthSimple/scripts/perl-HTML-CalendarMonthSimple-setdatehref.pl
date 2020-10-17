#!/usr/bin/perl
use strict;
use warnings;

=head1 NAME

perl-HTML-CalendarMonthSimple-setdatehref.pl - HTML::CalendarMonthSimple setdatehref example

=cut

use HTML::CalendarMonthSimple;
my $cal=HTML::CalendarMonthSimple->new(year=>2010, month=>7);
$cal->vcellalignment('middle');
$cal->cellalignment('center');
foreach my $day (1 .. $cal->Days_in_Month) {
  $cal->setdatehref($day, url($cal->year, $cal->month, $day));
}
print "<h1>setdatehref example</h1>", $cal->as_HTML;

sub url {
  my @ymd=@_;
  return sprintf("script.cgi?year=%s;month=%s;day=%s", @ymd);
}
