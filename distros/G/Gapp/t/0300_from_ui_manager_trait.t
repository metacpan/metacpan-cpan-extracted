#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More qw( no_plan );

use Gtk2 '-init';

use Gapp;
use Gapp::Meta::Widget::Native::Trait::FromUIManager;

my $w = Gapp::Toolbar->new(
    traits => [qw( FromUIManager )],
    ui => {
        files => [ 't/basic.ui' ],
        actions => [
            Gapp::Action->new(
                name => 'new',
                label => 'New',
                tooltip => 'New',
                icon => 'gtk-edit',
            ),
            Gapp::Action->new(
                name => 'edit',
                label => 'Edit',
                tooltip => 'Edit',
                icon => 'gtk-edit',
            ),
            Gapp::Action->new(
                name => 'delete',
                label => 'Edit',
                tooltip => 'Edit',
                icon => 'gtk-edit',
            ),
        ]
    },
    ui_widget => '/Toolbar',
);

ok $w, 'created gapp widget';
ok $w->gobject, 'created gtk widget';
ok $w->ui, 'created ui';
ok $w->ui->gobject, 'created ui gtk widget';
ok $w->ui->gobject->get_widget( '/Toolbar' );
