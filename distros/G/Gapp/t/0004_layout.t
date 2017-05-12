#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 7;

{   # create generic layout
    
    package My::Layout;
    use Gapp::Layout;
    
    add 'Gapp::Widget', to 'Gapp::Container', sub {
        my ( $container, $child ) = @_;
        $container->gobject->add( $child->gobject );
    };
    
    add 'Gapp::Label', to 'Gapp::Window', sub {
        my ( $container, $child ) = @_;
        $container->gobject->add( $child->gobject );
    };
    
    
    
    package main;
    
    my $layout =  My::Layout->Layout;
    ok ( $layout, 'created layout object' );
    ok ( $layout->has_packer( 'Gapp::Widget', 'Gapp::Container' ), 'has packer' );
    ok ( $layout->get_packer( 'Gapp::Widget', 'Gapp::Container' ), 'got packer' );
}

{  # test the default layout
    package main;
    
    use Gapp::Layout::Default;
    
    my $layout =  Gapp::Layout::Default->Layout;
    ok ( $layout, 'created layout object' );
    ok ( $layout->get_packer( 'Gapp::Widget', 'Gapp::Container' ), 'got packer' );
}


{   # create a subclass of the default layout
    package Gapp::Layout::Subclass;

    use Gapp::Layout;
    extends 'Gapp::Layout::Default';
    
    build 'Gapp::Window', sub {
        my ( $layout, $widget ) = @_;
        $layout->parent->build_widget( $widget );
    };
    
    add 'Gapp::Label', to 'Gapp::Dialog', sub {
        my ( $layout, $widget, $container ) = @_;
    };


    package main;
    
    use Gapp::Layout::Default;
    
    my $layout =  Gapp::Layout::Default->Layout;
    ok ( $layout, 'created layout object' );
    ok ( $layout->get_packer( 'Gapp::Widget', 'Gapp::Container' ), 'got packer' );
}






