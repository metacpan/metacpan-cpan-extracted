#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 11;

use Gtk2 '-init';




use Scalar::Util qw(refaddr);

{
    use_ok 'Gapp::TextTagTable';
    my $w = Gapp::TextTagTable->new;
    isa_ok $w, q[Gapp::TextTagTable];
    isa_ok $w->gobject, q[Gtk2::TextTagTable];
}


{
    use_ok 'Gapp::TextBuffer';
    my $w = Gapp::TextBuffer->new;
    isa_ok $w, q[Gapp::TextBuffer];
    isa_ok $w->gobject, q[Gtk2::TextBuffer];
}


{  # buffer with tag table
    my $t = Gapp::TextTagTable->new;
    my $w = Gapp::TextBuffer->new( tag_table => $t );
    is refaddr $w->gobject->get_tag_table, refaddr $t->gobject, q[tag_table assigned to buffer];
}



{ # text view construction
    use_ok 'Gapp::TextView';
 
    my $w = Gapp::TextView->new;
    isa_ok $w, q[Gapp::TextView];
    isa_ok $w->gobject, q[Gtk2::TextView];
}


{ # text view with buffer
    my $b = Gapp::TextBuffer->new;
    my $w = Gapp::TextView->new( buffer => $b );
    
    is refaddr $w->gobject->get_buffer, refaddr $b->gobject, q[gobject buffer set from attr];
}
