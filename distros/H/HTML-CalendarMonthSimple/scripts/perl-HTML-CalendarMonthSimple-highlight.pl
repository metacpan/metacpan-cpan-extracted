#!/usr/bin/perl
use strict;
use warnings;

=head1 NAME

perl-HTML-CalendarMonthSimple-highlight.pl - HTML::CalendarMonthSimple example using new highlight method

=cut

use HTML::CalendarMonthSimple;
my $cal=HTML::CalendarMonthSimple->new(year=>2010, month=>7);
$cal->vcellalignment('middle');
$cal->cellalignment('center');
$cal->highlight(5,10,15,20,25);
print "<h1>Highlight Test</h1>", $cal->as_HTML;
