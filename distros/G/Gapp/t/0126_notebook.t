#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 6;

use Gtk2 '-init';

use Gapp::Label;
use Gapp::VBox;
use Gapp::Window;
use_ok 'Gapp::Notebook';



{ # basic construction test
    my $w = Gapp::Notebook->new;
    isa_ok $w, 'Gapp::Notebook';
    isa_ok $w->gobject,  'Gtk2::Notebook';
}


{ # add pages
    my $page = Gapp::VBox->new(
        traits => [qw( NotebookPage )],
        content => [
            Gapp::Label->new( text => 'Hello World!'),
        ]
    );
    
    ok $page, 'created page';
    
    my $w = Gapp::Notebook->new(
        content => [
            $page
        ]
    );
    
    ok $w, 'created notebook with page';
    
    ok $w->gobject->get_children, 'notebook has page';
    
}


