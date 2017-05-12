#!/usr/bin/perl -w
use Gtk2 '-init';
use strict;
use warnings;


use Gapp;

Gapp::Assistant->new(
    title => 'Assistant',
    content => [
        Gapp::AssistantPage->new(
            name => 'intro',
            title => 'Intro',
            type => 'intro',
            icon => 'gtk-help',
            content => [
                Gapp::Label->new( text => 'Intro' ),
            ]
        ),
        Gapp::AssistantPage->new(
            name => 'content',
            title => 'Content',
            type => 'content',
            icon => 'gtk-help',
            content => [
                Gapp::Label->new( text => 'Content' ),
            ]
        ),
        Gapp::AssistantPage->new(
            name => 'summary',
            title => 'Summary',
            type => 'summary',
            icon => 'gtk-help',
            content => [
                Gapp::Label->new( text => 'Summary' ),
            ]
        ),
    ],
    signal_connect => [
        ['delete-event' => sub { $_[0]->gobject->destroy }],
        ['close' =>  sub { $_[0]->gobject->destroy }],
        ['cancel' =>  sub { $_[0]->gobject->destroy }],
        ['destroy' => sub { Gtk2->main_quit }],
    ],
)->show_all;

Gtk2->main;
