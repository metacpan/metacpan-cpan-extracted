#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 5;

use Gtk2 '-init';



use Gapp::Label;
use Gapp::VBox;

{
    use_ok 'Gapp::Assistant';
    
    my $w = Gapp::Assistant->new;
    isa_ok $w, q[Gapp::Assistant];
    isa_ok $w->gobject, q[Gtk2::Assistant];
    

}


{
    my $page = Gapp::VBox->new(
        traits => [qw( AssistantPage )],
        content => [
            Gapp::Label->new( text => 'Hello World!'),
        ]
    );
    
    ok $page, 'created page';
    
    my $w = Gapp::Assistant->new( content => [ $page ] );
    ok $w, 'created assistant with page';
}



