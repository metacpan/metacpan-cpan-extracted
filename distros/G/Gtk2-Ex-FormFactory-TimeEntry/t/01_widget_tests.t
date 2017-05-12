#!/usr/bin/perl -w
use strict;
use warnings;

use lib qw(../lib);
use lib qw(lib);
use Test::More 'no_plan';

use_ok 'Gtk2::Ex::FormFactory::DateEntry';

use Gtk2 '-init';
use Gtk2::Ex::DateEntry;
use Gtk2::Ex::FormFactory;

package Test::Object;
use Moose;
use MooseX::FollowPBP;

has 'attribute' => (is => 'rw', default => '2009-01-01');

package main;


my $context = Gtk2::Ex::FormFactory::Context->new;
$context->add_object(
    name       => 'object' ,
    object     => Test::Object->new,
);

my $dialog  = Gtk2::Ex::FormFactory->new (
    context  => $context,
    content => Gtk2::Ex::FormFactory::Window->new(
        title   => 'Gtk2::Ex::FormFactory::DateEntry Test',
        content => [
            Gtk2::Ex::FormFactory::DateEntry->new(
                attr => 'object.attribute',
            ),
        ],
    ),
);


ok($dialog, 'form factory instantiated');