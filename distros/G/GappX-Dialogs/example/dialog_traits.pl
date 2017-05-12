#!/usr/bin/perl -w
use strict;
use warnings;



package Foo::Layout;
use Gapp::Layout;
extends 'Gapp::Layout::Default';

style 'Gapp::Dialog', sub {
    my ( $layout, $widget ) = @_;
    $widget->properties->{has_separator} ||= 0;
    $widget->properties->{border_width} ||= 6;
    $layout->parent->style_widget( $widget );
};

build 'Gapp::Dialog', sub {
    my ( $layout, $widget ) = @_;
    $widget->gobject->get_content_area->set_spacing( 6 );
    $layout->parent->build_widget( $widget );
};

style 'Gapp::HBox', sub {
    my ( $layout, $widget ) = @_;
    $widget->properties->{spacing} = 12;
    $widget->properties->{border_width} = 6  if ! defined $widget->properties->{border_width};
    $layout->parent->style_widget( $widget );
};

style 'Gapp::VBox', sub {
    my ( $layout, $widget ) = @_;
    $widget->properties->{spacing} = 12;
    $layout->parent->style_widget( $widget );
};




package main;

use Gapp;
use GappX::Dialogs;

use Gapp::Actions::Basic qw(Quit);

my @params = (
    text => 'Primary Message',
    secondary => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam malesuada dignissim augue.',
    layout => 'Foo::Layout',
);

my $w = Gapp::Window->new(
    layout => 'Foo::Layout',
    content => [
        Gapp::VButtonBox->new(
            content => [
                Gapp::Button->new(
                    icon => 'gtk-dialog-question',
                    label => 'ConfirmDialog',
                    action =>  [sub {
                        my $w = Gapp::Dialog->new( traits => [qw(ConfirmDialog)], @params );
                        $w->run;
                        $w->destroy;
                    }]
                ),
                Gapp::Button->new(
                    icon => 'gtk-dialog-error',
                    label => 'ErrorDialog',
                    action =>  [sub {
                        my $w = Gapp::Dialog->new( traits => [qw(ErrorDialog)], @params, alert => 1 );
                        $w->run;
                        $w->destroy;
                    }]
                ),
                Gapp::Button->new(
                    icon => 'gtk-dialog-info',
                    label => 'InfoDialog',
                    action =>  [sub {
                        my $w = Gapp::Dialog->new( traits => [qw(InfoDialog)], @params );
                        $w->run;
                        $w->destroy;
                    }]
                ),
                Gapp::Button->new(
                    icon => 'gtk-dialog-info',
                    label => 'MessageDialog',
                    action =>  [sub {
                        my $w = Gapp::Dialog->new( traits => [qw(MessageDialog)], @params );
                        $w->run;
                        $w->destroy;
                    }]
                ),
                Gapp::Button->new(
                    icon => 'gtk-dialog-question',
                    label => 'QuestionDialog',
                    action =>  [sub {
                        my $w = Gapp::Dialog->new( traits => [qw(QuestionDialog)], @params );
                        $w->run;
                        $w->destroy;
                    }]
                ),
                Gapp::Button->new(
                    icon => 'gtk-dialog-warning',
                    label => 'WarningDialog',
                    action =>  [sub {
                        my $w = Gapp::Dialog->new( traits => [qw(WarningDialog)], @params );
                        $w->run;
                        $w->destroy;
                    }]
                ),
            ]
        )
    ],
    signal_connect => [
        [ delete_event => Quit ],
    ]
);

$w->show_all;

Gapp->main;




