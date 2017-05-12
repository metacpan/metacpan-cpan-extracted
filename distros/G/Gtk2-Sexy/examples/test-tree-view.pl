#!/usr/bin/perl

use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 -init;
use Gtk2::Sexy;

sub get_tooltip {
    my ($treeview, $path, $column) = @_;

    my $model = $treeview->get_model;
    my $iter  = $model->get_iter($path);
    my ($name, $stock) = $model->get($iter, 0, 1);

    my $box   = Gtk2::HBox->new(FALSE, 6);
    my $image = Gtk2::Image->new_from_stock($stock, 'dialog');
    my $label = Gtk2::Label->new;
    $label->set_markup( "<span size=\"large\" weight=\"bold\">$name</span>" );
    $box->pack_start($image, FALSE, TRUE, 0);
    $box->pack_start($label, FALSE, TRUE, 0);

    $box->show_all;
    return $box;
}

my $window = Gtk2::Window->new;
$window->show;
$window->set_title('Sexy Tree View Test');
$window->set_border_width(3);
$window->signal_connect( 'destroy' => sub { Gtk2->main_quit } );

my $swin = Gtk2::ScrolledWindow->new;
$swin->show;
$swin->set_policy('automatic', 'automatic');
$swin->set_shadow_type('etched-in');
$window->add($swin);

my $treeview = Gtk2::Sexy::TreeView->new;
$treeview->show;
$swin->add($treeview);

my $store = Gtk2::TreeStore->new('Glib::String', 'Glib::String');
$treeview->set_model($store);

$treeview->signal_connect( 'get-tooltip' => \&get_tooltip );

my $text = Gtk2::CellRendererText->new;
my $col  = Gtk2::TreeViewColumn->new_with_attributes('Column 1', $text, 'text', 0);
$treeview->append_column($col);

my $a = $store->append(undef);
$store->set($a, 0 => 'a', 1 => 'gtk-dialog-authentication');
my $b = $store->append($a);
$store->set($b, 0 => 'one', 1 => 'gtk-dialog-error');
$b = $store->append($a);
$store->set($b, 0 => 'two', 1 => 'gtk-dialog-info');
$b = $store->append($a);
$store->set($b, 0 => 'three', 1 => 'gtk-dialog-question');
$a = $store->append(undef);
$store->set($a, 0 => 'b', 1 => 'gtk-dialog-warning');
$b = $store->append($a);
$store->set($b, 0 => 'one', 1 => 'gtk-dialog-authentication');
$b = $store->append($a);
$store->set($b, 0 => 'two', 1 => 'gtk-dialog-error');
$b = $store->append($a);
$store->set($b, 0 => 'three', 1 => 'gtk-dialog-info');

Gtk2->main;
