#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gapp '-init';
use_ok 'Gapp::DateEntry';

my $w = Gapp::DateEntry->new( value => '2011-04-12' );
isa_ok $w, 'Gapp::DateEntry';
isa_ok $w->gobject, 'Gapp::Gtk2::DateEntry';

