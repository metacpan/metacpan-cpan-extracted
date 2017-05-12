#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gapp '-init';
use_ok 'Gapp::TimeEntry';

my $w = Gapp::TimeEntry->new( value => '2011-04-12' );
isa_ok $w, 'Gapp::TimeEntry';
isa_ok $w->gobject, 'Gapp::Gtk2::TimeEntry';

