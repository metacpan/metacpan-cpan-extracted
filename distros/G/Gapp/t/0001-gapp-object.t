#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use_ok 'Gapp::Object';


{   # object contruction
    my $o = Gapp::Object->new( gclass => 'Gtk2::TextBuffer' );
    isa_ok $o, 'Gapp::Object';
    isa_ok $o->gobject, 'Gtk2::TextBuffer';
}


