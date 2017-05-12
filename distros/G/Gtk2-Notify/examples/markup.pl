#!/usr/bin/perl

use strict;
use warnings;
use Gtk2::Notify -init, 'Markup';

my $n = Gtk2::Notify->new(
        'Summary',
        'Some <b>bold</b>, <u>underlined</u>, <i>italic</i>, '
        . '<a href="http://www.google.com">linked</a> text'
);
$n->show;
