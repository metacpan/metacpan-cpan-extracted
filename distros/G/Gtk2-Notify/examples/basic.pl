#!/usr/bin/perl

use strict;
use warnings;
use Gtk2::Notify -init, 'Basic';

my $n = Gtk2::Notify->new('Summary', 'This is some sample content');
$n->show;
