#!/usr/bin/perl

use strict;
use warnings;
use Gtk2::Notify -init, 'XY';

my $n = Gtk2::Notify->new('X, Y Test', 'This notification should point to 150, 10');

$n->set_hint_int32('x', 150);
$n->set_hint_int32('y', 10);

$n->show;
