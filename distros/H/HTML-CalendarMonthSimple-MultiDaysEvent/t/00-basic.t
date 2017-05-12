#!/usr/bin/perl
use strict;
use Test::More tests => 5;

BEGIN { use_ok('HTML::CalendarMonthSimple::MultiDaysEvent',qw(add_event multidays_HTML)); }
ok($HTML::CalendarMonthSimple::MultiDaysEvent::VERSION) if $HTML::CalendarMonthSimple::MultiDaysEvent::VERSION or 1;
ok(my $cal = new HTML::CalendarMonthSimple::MultiDaysEvent('year'=>2005,'month'=>10));
ok($cal->add_event( date => 10, event => 'blah', length => 3 ));
ok($cal->multidays_HTML);
