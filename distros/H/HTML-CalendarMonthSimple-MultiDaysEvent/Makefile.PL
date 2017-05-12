#!/usr/local/bin/perl
use inc::Module::Install;

name        ('HTML-CalendarMonthSimple-MultiDaysEvent');
author      ('Hsin-Chan Chien <hcchien@hcchien.org>');
abstract    ('add the mukti days event view for CalendarMonthSimple');
license	    ('perl');
version_from('lib/HTML/CalendarMonthSimple/MultiDaysEvent.pm');
requires    ('HTML::CalendarMonthSimple');
WriteAll    ( sign => 1 );
