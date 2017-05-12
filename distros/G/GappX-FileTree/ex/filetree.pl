#!/usr/bin/perl -w
use strict;
use warnings;

use lib qw(lib ..\lib);

use Gapp;
use GappX::FileTree;


my $t = GappX::FileTree->new;
$t->update;

my $w = Gapp::Window->new(
    title => 'FileTree Example',
    content => [$t],
);

$w->show_all;

Gapp->main;