#!/usr/bin/perl -w
use strict;
use warnings;

use lib qw(lib ../lib);

use Gapp;
use GappX::NoticeBox;

use Gapp::Actions::Basic qw( Quit );

my $box = GappX::NoticeBox->new;

Gapp::Window->new(
    title => 'GappX::NoticeBox example',
    content => [
        Gapp::Button->new(
            icon => 'gtk-info',
            label => 'Display Notification',
            action => [
                sub {
                    my $n = GappX::Notice->new(
                        icon => 'gtk-info',
                        text => 'Hello World!',
                        action => [sub { print @_, "\n" }],
                    );
                    $box->display( $n );
                }
            ]
        )
    ],
    signal_connect => [
        [ delete_event => Quit ],
    ]
)->show_all;


Gapp->main;
