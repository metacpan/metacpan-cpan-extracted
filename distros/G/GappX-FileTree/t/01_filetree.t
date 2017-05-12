#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use_ok 'GappX::FileTree';


my $t = GappX::FileTree->new;
isa_ok $t, 'GappX::FileTree';
isa_ok $t->gobject, 'Gtk2::TreeView';

use Gapp;
$t->update;

