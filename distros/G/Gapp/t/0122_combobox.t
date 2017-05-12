#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 11;

use Gtk2 '-init';
use_ok 'Gapp::ComboBox';


{   # Basic combox box with strings
    my $w = Gapp::ComboBox->new(
        values => [ 'foo', 'bar', 'baz', ]
    );
    ok $w, 'created gapp widget';
    ok $w->gobject, 'created gtk widget';
    
    my $model = $w->gobject->get_model;
    my $iter = $model->get_iter_first;
    ok $model->get( $iter ), 'got foo';
    
    $iter = $model->iter_next( $iter );
    ok $model->get( $iter ), 'got bar';
    
    $iter = $model->iter_next( $iter );
    ok $model->get( $iter ), 'got baz';
}


{   # Basic combox box with sub as values
    my $w = Gapp::ComboBox->new(
        values => sub { 'foo', 'bar', 'baz' }
    );
    ok $w, 'created gapp widget';
    ok $w->gobject, 'created gtk widget';
    
    my $model = $w->gobject->get_model;
    my $iter = $model->get_iter_first;
    ok $model->get( $iter ), 'got foo';
    
    $iter = $model->iter_next( $iter );
    ok $model->get( $iter ), 'got bar';
    
    $iter = $model->iter_next( $iter );
    ok $model->get( $iter ), 'got baz';
    
}


