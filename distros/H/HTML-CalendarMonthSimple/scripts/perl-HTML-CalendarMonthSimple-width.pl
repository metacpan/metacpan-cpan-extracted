#!/usr/bin/perl
use strict;
use warnings;

=head1 NAME

perl-HTML-CalendarMonthSimple-width.pl - HTML::CalendarMonthSimple example

=cut

use HTML::CalendarMonthSimple;
my $cal=HTML::CalendarMonthSimple->new(year=>2010, month=>7);

$cal->saturday('S');
$cal->sunday('S');
$cal->weekdays(qw{M T W T F});
$cal->vcellalignment('middle');
$cal->cellalignment('center');

foreach my $width ("90%", 900, "100%", 1000) {
  $cal->width($width);
  print sprintf("<h1>Width %s</h1>", $cal->width),
        $cal->as_HTML;
}
