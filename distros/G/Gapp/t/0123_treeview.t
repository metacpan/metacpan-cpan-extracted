#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 6;

use Gtk2 '-init';




{
    use_ok 'Gapp::TreeViewColumn';
    
    my $w = Gapp::TreeViewColumn->new(
        name => 'foo',
        title => 'Foo',
        renderer => 'text',
    );
    
    isa_ok $w, 'Gapp::TreeViewColumn';
    isa_ok $w->gobject, 'Gtk2::TreeViewColumn';
}


{   # Basic combox box with sub as values
    
    use_ok 'Gapp::TreeView';
    use Gapp::ListStore;
    
    my $w = Gapp::TreeView->new(
        model => Gapp::ListStore->new( columns => [ 'Glib::String' ] ),
        columns => [
            Gapp::TreeViewColumn->new(
                name => 'foo',
                title => 'Foo',
                renderer => 'text'
            ),
        ]
    );
    
    isa_ok $w, 'Gapp::TreeView';
    isa_ok $w->gobject, 'Gtk2::TreeView';
}


