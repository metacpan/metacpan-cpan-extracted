package HTML::CalendarMonthSimple::MultiDaysEvent;

our $VERSION = '0.03';

use strict;
use base 'HTML::CalendarMonthSimple';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new;;
    bless $self,$class; 
    $self->{events}->{$_} = [] for (1..31);
    return $self;
}

sub multidays_HTML {
   my $self = shift;
   my %params = @_; 
   my $html = '';
   my(@days,$weeks,$WEEK,$DAY);

   # To make the grid even, pad the start of the series with 0s
   @days = (1 .. Date::Calc::Days_in_Month($self->year(),$self->month() ) );
   if ($self->weekstartsonmonday()) {
       foreach (1 .. (Date::Calc::Day_of_Week($self->year(),
                                              $self->month(),1) -1 )) {
          unshift(@days,0);
       }
   }
   else {
       foreach (1 .. (Date::Calc::Day_of_Week($self->year(),
                                              $self->month(),1)%7) ) {
          unshift(@days,0);
       }
   }
   $weeks = int((scalar(@days)+6)/7);
   # And pad the end as well, to avoid "uninitialized value" warnings
   foreach (scalar(@days)+1 .. $weeks*7) {
      push(@days,0);
   }

   # Define some scalars for generating the table
   my $border = $self->border();
   my $tablewidth = $self->width();
   $tablewidth =~ m/^(\d+)(\%?)$/; my $cellwidth = (int($1/7))||'14'; if ($2) { $cellwidth .= '%'; }
   my $header = $self->header();
   my $cellalignment = $self->cellalignment();
   my $vcellalignment = $self->vcellalignment();
   my $contentfontsize = $self->contentfontsize();
   my $bgcolor = $self->bgcolor();
   my $weekdaycolor = $self->weekdaycolor() || $self->bgcolor();
   my $weekendcolor = $self->weekendcolor() || $self->bgcolor();
   my $todaycolor = $self->todaycolor() || $self->bgcolor();
   my $contentcolor = $self->contentcolor() || $self->contentcolor();
   my $weekdaycontentcolor = $self->weekdaycontentcolor() || $self->contentcolor();
   my $weekendcontentcolor = $self->weekendcontentcolor() || $self->contentcolor();
   my $todaycontentcolor = $self->todaycontentcolor() || $self->contentcolor();
   my $bordercolor = $self->bordercolor() || $self->bordercolor();
   my $weekdaybordercolor = $self->weekdaybordercolor() || $self->bordercolor();
   my $weekendbordercolor = $self->weekendbordercolor() || $self->bordercolor();
   my $todaybordercolor = $self->todaybordercolor() || $self->bordercolor();
   my $weekdayheadercolor = $self->weekdayheadercolor() || $self->bgcolor();
   my $weekendheadercolor = $self->weekendheadercolor() || $self->bgcolor();
   my $headercontentcolor = $self->headercontentcolor() || $self->contentcolor();
   my $weekdayheadercontentcolor = $self->weekdayheadercontentcolor() || $self->contentcolor();
   my $weekendheadercontentcolor = $self->weekendheadercontentcolor() || $self->contentcolor();
   my $headercolor = $self->headercolor() || $self->bgcolor();
   my $cellpadding = $self->cellpadding();
   my $cellspacing = $self->cellspacing();
   my $sharpborders = $self->sharpborders();
   my $cellheight = $self->cellheight();
   my $cellclass = $self->cellclass();
   my $tableclass = $self->tableclass();
   my $weekdaycellclass = $self->weekdaycellclass() || $self->cellclass();
   my $weekendcellclass = $self->weekendcellclass() || $self->cellclass();
   my $todaycellclass = $self->todaycellclass() || $self->cellclass();
   my $headerclass = $self->headerclass() || $self->cellclass();
   my $nowrap = $self->nowrap();

   # Get today's date, in case there's a todaycolor()
   my($todayyear,$todaymonth,$todaydate) = ($self->today_year(),$self->today_month(),$self->today_date());

   # the table declaration - sharpborders wraps the table inside a table cell
   if ($sharpborders) {
      $html .= "<table border=\"0\"";
      $html .= " class=\"$tableclass\"" if defined $tableclass;
      $html .= " width=\"$tablewidth\"" if defined $tablewidth;
      $html .= " cellpadding=\"0\" cellspacing=\"0\">\n";
      $html .= "<tr valign=\"top\" align=\"left\">\n";
      $html .= "<td align=\"left\" valign=\"top\"";
      $html .= " bgcolor=\"$bordercolor\"" if defined $bordercolor;
      $html .= ">";
      $html .= "<table border=\"0\" cellpadding=\"3\" cellspacing=\"1\" width=\"100%\">";
   }
   else {
      $html .= "<table";
      $html .= " class=\"$tableclass\"" if defined $tableclass;
      $html .= " border=\"$border\"" if defined $border;
      $html .= " width=\"$tablewidth\"" if defined $tablewidth;
      $html .= " bgcolor=\"$bgcolor\"" if defined $bgcolor;
      $html .= " bordercolor=\"$bordercolor\"" if defined $bordercolor;
      $html .= " cellpadding=\"$cellpadding\"" if defined $cellpadding;
      $html .= " cellspacing=\"$cellspacing\""  if defined $cellspacing;
      $html .= ">\n";
   }
   # the header
   if ($header) {
      $html .= "<tr><td colspan=\"7\"";
      $html .= " bgcolor=\"$headercolor\"" if defined $headercolor;
      $html .= " class=\"$headerclass\"" if defined $headerclass;
      $html .= ">";
      $html .= "<font color=\"$headercontentcolor\">" if defined $headercontentcolor;
      $html .= $header;
      $html .= "</font>"  if defined $headercontentcolor;
      $html .= "</td></tr>\n";
   }
   # the names of the days of the week
   if ($self->showweekdayheaders) {
      my $celltype = $self->weekdayheadersbig() ? "th" : "td";
      my @weekdays = $self->weekdays();

      my $saturday_html = "<$celltype"
                        . ( defined $weekendheadercolor 
                            ? qq| bgcolor="$weekendheadercolor"| 
                            : '' )
                        . ( defined $weekendcellclass 
                            ? qq| class="$weekendcellclass"| 
                            : '' ) 
                        . ">"
                        . ( defined $weekendheadercontentcolor 
                            ? qq|<font color="$weekendheadercontentcolor">| 
                            : '' ) 
                        . $self->saturday()
                        . ( defined $weekendheadercontentcolor 
                            ? qq|</font>|
                            : '' )
                        . "</$celltype>\n";

      my $sunday_html   = "<$celltype"
                        . ( defined $weekendheadercolor 
                            ? qq| bgcolor="$weekendheadercolor"| 
                            : '' )
                        . ( defined $weekendcellclass 
                            ? qq| class="$weekendcellclass"| 
                            : '' ) 
                        . ">"
                        . ( defined $weekendheadercontentcolor 
                            ? qq|<font color="$weekendheadercontentcolor">| 
                            : '' ) 
                        . $self->sunday()
                        . ( defined $weekendheadercontentcolor 
                            ? qq|</font>|
                            : '' )
                        . "</$celltype>\n";
      
      my $weekday_html = '';
      foreach (@weekdays) { # draw the weekday headers

         $weekday_html  .= "<$celltype"
                        . ( defined $weekendheadercolor 
                            ? qq| bgcolor="$weekdayheadercolor"| 
                            : '' )
                        . ( defined $weekendcellclass 
                            ? qq| class="$weekdaycellclass"| 
                            : '' ) 
                        . ">"
                        . ( defined $weekdayheadercontentcolor 
                            ? qq|<font color="$weekdayheadercontentcolor">| 
                            : '' ) 
                        . $_
                        . ( defined $weekdayheadercontentcolor 
                            ? qq|</font>|
                            : '' )
                        . "</$celltype>\n";
      }

      $html .= "<tr>\n";
      if ($self->weekstartsonmonday()) {
        $html .= $weekday_html
              .  $saturday_html
              .  $sunday_html;
      }
      else {
        $html .= $sunday_html
              .  $weekday_html
              .  $saturday_html;
      }
      $html .= "</tr>\n";
   }

   my $_saturday_index = 6;
   my $_sunday_index   = 0;
   if ($self->weekstartsonmonday()) {
       $_saturday_index = 5;
       $_sunday_index   = 6;
   }
   # now do each day, the actual date-content-containing cells
   foreach $WEEK (0 .. ($weeks-1)) {
      my $weekevents = 0;
      my %prerow;
      my %daycol;
      my $firstday = $days[(7*$WEEK)];
      my $lastday = $firstday + 6;
      my $firstevent;

      for $DAY (0 .. 6) {
          my $thisday = $days[((7*$WEEK)+$DAY)];
          if ($#{$self->{events}->{$thisday}} > -1) {
              $firstevent = $thisday unless ($firstevent);
              $weekevents += scalar(@{$self->{events}->{$thisday}});
              for my $event (sort { $a->{length} <=> $b->{length} } (@{$self->{events}->{$thisday}})) {
                  for (0 .. $event->{length} - 1) {
                      $prerow{$thisday+$_} = $weekevents unless ($prerow{$thisday+$_});
                  }
                  if ($thisday + ($event->{length} - 1) > $lastday) {
		      $self->add_event( date  => $lastday+1,
					event  => $event->{event},
					length => $event->{length} - 
						  ($lastday - $thisday + 1) );
		      $event->{length} = $lastday-$thisday+1;
		  }
              }
          }
      }
      $html .= "<tr style=\"line-height:4em;\">\n";
      foreach $DAY ( 0 .. 6 ) {
         my($thiscontent,$thisday,$thisbgcolor,$thisbordercolor,$thiscontentcolor,$thiscellclass);
         $thisday = $days[((7*$WEEK)+$DAY)];

         # Get the cell's coloration and CSS class
         if ($self->year == $todayyear && $self->month == $todaymonth && $thisday == $todaydate)  { 
             $thisbgcolor = $self->datecolor($thisday) || $todaycolor;
             $thisbordercolor = $self->datebordercolor($thisday) || $todaybordercolor;
             $thiscontentcolor = $self->datecontentcolor($thisday) || $todaycontentcolor;
             $thiscellclass = $self->datecellclass($thisday) || $todaycellclass;
         } elsif (($DAY == $_sunday_index) || ($DAY == $_saturday_index))   { 
             $thisbgcolor = $self->datecolor($thisday) || $weekendcolor;
             $thisbordercolor = $self->datebordercolor($thisday) || $weekendbordercolor;
             $thiscontentcolor = $self->datecontentcolor($thisday) || $weekendcontentcolor;
             $thiscellclass = $self->datecellclass($thisday) || $weekendcellclass;
         } else { 
             $thisbgcolor = $self->datecolor($thisday) || $weekdaycolor;
             $thisbordercolor = $self->datebordercolor($thisday) || $weekdaybordercolor;
             $thiscontentcolor = $self->datecontentcolor($thisday) || $weekdaycontentcolor;
             $thiscellclass = $self->datecellclass($thisday) || $weekdaycellclass;
         }

         # mark the date, and we should count the events first.
         my $rowspan = $prerow{$thisday} || (1 + $weekevents);
         # Done with this cell - push it into the table
         $html .= "<td style=\"border-bottom-width:0px;\"";
         $html .= " nowrap" if $nowrap;
         $html .= " class=\"$thiscellclass\"" if defined $thiscellclass;
         $html .= " height=\"$cellheight\"" if defined $cellheight;
         $html .= " width=\"$cellwidth\"" if defined $cellwidth;
         $html .= " valign=\"top\"";
         $html .= " align=\"$cellalignment\"" if defined $cellalignment;
         $html .= " bgcolor=\"$thisbgcolor\"" if defined $thisbgcolor;
         $html .= " bordercolor=\"$thisbordercolor\"" if defined $thisbordercolor;
         $html .= " rowspan=\"$rowspan\"";
         $html .= ">";
         $html .= "<font" if (defined $thiscontentcolor ||
                              defined $contentfontsize);
         $html .= " color=\"$thiscontentcolor\"" if defined $thiscontentcolor;
         $html .= " size=\"$contentfontsize\""  if defined $contentfontsize;
         $html .= ">" if (defined $thiscontentcolor ||
                          defined $contentfontsize);
         $html .= "<b>$thisday</b>\n" if ($thisday);
         $html .= "</font>" if (defined $thiscontentcolor ||
                                defined $contentfontsize);
         $html .= "</td>\n";
      }
      $html .= "</tr>\n";
              my $i = 1;
      for $DAY (0 .. 6) {
          my $thisday = $days[((7*$WEEK)+$DAY)];
          if (exists $self->{events}->{$thisday}) {
              for my $event (sort { $a->{length} <=> $b->{length} } @{$self->{events}->{$thisday}}) {
                  my $colspan = $event->{length};
                  my $preoffset = $weekevents - $i + 1;
                  $html .= "<tr>\n";
                  for (0 .. ($thisday - $firstevent - 1)) {
                      if ($preoffset) {
			  $html .= "<td rowspan=$preoffset style=\"border-top-width:0px;border-bottom-width:0px;\" boder=0 class=\"calweekendcell\" width=\"14%\" valign=\"top\" align=\"left\"></td>\n";
                      }
                  }
                  $html .= "<td bgcolor=#EEE colspan=$colspan style=\"border-top-width:0px;border-bottom-width:0px;\" width=\"14%\" valign=\"top\">".$event->{event}."</td>\n";
                  $html .= "</tr>\n";
                  $firstevent = $thisday;
                  $i++;
              }
          }
      }
      $html .= "<tr style=\"line-height:4em;\">\n";
      foreach $DAY ( 0 .. 6 ) {
         my($thiscontent,$thisday,$thisbgcolor,$thisbordercolor,$thiscontentcolor,$thiscellclass);
         $thisday = $days[((7*$WEEK)+$DAY)];

         # Get the cell's coloration and CSS class
         if ($self->year == $todayyear && $self->month == $todaymonth && $thisday == $todaydate)  { 
             $thisbgcolor = $self->datecolor($thisday) || $todaycolor;
             $thisbordercolor = $self->datebordercolor($thisday) || $todaybordercolor;
             $thiscontentcolor = $self->datecontentcolor($thisday) || $todaycontentcolor;
             $thiscellclass = $self->datecellclass($thisday) || $todaycellclass;
         } elsif (($DAY == $_sunday_index) || ($DAY == $_saturday_index))   { 
             $thisbgcolor = $self->datecolor($thisday) || $weekendcolor;
             $thisbordercolor = $self->datebordercolor($thisday) || $weekendbordercolor;
             $thiscontentcolor = $self->datecontentcolor($thisday) || $weekendcontentcolor;
             $thiscellclass = $self->datecellclass($thisday) || $weekendcellclass;
         } else { 
             $thisbgcolor = $self->datecolor($thisday) || $weekdaycolor;
             $thisbordercolor = $self->datebordercolor($thisday) || $weekdaybordercolor;
             $thiscontentcolor = $self->datecontentcolor($thisday) || $weekdaycontentcolor;
             $thiscellclass = $self->datecellclass($thisday) || $weekdaycellclass;
         }

         # mark the date, and we should count the events first.
         my $rowspan = $prerow{$thisday} || (1+$weekevents);
         # Done with this cell - push it into the table
         $html .= "<td style=\"line-height:5px;border-top-width:0px;line-height:4em;\"";
         $html .= " nowrap" if $nowrap;
         $html .= " class=\"$thiscellclass\"" if defined $thiscellclass;
         $html .= " height=\"$cellheight\"" if defined $cellheight;
         $html .= " width=\"$cellwidth\"" if defined $cellwidth;
         $html .= " valign=\"$vcellalignment\"" if defined $vcellalignment;
         $html .= " align=\"$cellalignment\"" if defined $cellalignment;
         $html .= " bgcolor=\"$thisbgcolor\"" if defined $thisbgcolor;
         $html .= " bordercolor=\"$thisbordercolor\"" if defined $thisbordercolor;
         $html .= ">&nbsp;";
         $html .= "</td>\n";
      }
   }
   $html .= "</table>\n";

   # if sharpborders, we need to break out of the enclosing table cell
   if ($sharpborders) {
      $html .= "</td>\n</tr>\n</table>\n";
   }

   return $html;
}

sub add_event {
    my $self = shift;
    my %params = @_;
    my $date = $params{date};
    $date =~ s/^0*//;
    my $event = {};
    $event->{event} = $params{event};
    $event->{length} = $params{length} || 1;
    push @{$self->{events}->{$date}}, $event;
    return 1;
}

1;

__END__

=head1 NAME

HTML::CalendarMonthSimple::MultiDaysEvent - enable create the multi days events for CalendarMonthSimple

=head1 VERSION

This document describes version 0.01 of HTML::CalendarMonthSimple::MultiDaysEvent, released 
May 5, 2005.

=head1 SYNOPSIS

#!/usr/bin/perl

use HTML::CalendarMonthSimple::MultiDaysEvent;

my $cal = new HTML::CalendarMonthSimple::MultiDaysEvent('year'=>2005,'month'=>10);
$cal->add_event( date => 10, event => 'foo', length => 3 );
$cal->add_event( date => 14, event => 'bar', length => 1 );
print $cal->multidays_HTML;

=head1 DESCRIPTION

This module provides the new methods for CalendarMonthSimple to allow users
add the events with multi days.

If you want to use the multi days event. you should use the method add_event
to new the events and multidays_HTML to build the HTML with multi days view.

=head1 AUTHORS

Hsin-Chan Chien E<lt>hcchien@hcchien.orgE<gt>

=head1 COPYRIGHT

Copyright 2005 by Hsin-Chan Chien E<lt>hcchien@hcchien.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
