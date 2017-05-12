#!/usr/bin/perl

use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 -init;
use Gtk2::Sexy;

my $window = Gtk2::Window->new();
$window->show();
$window->set_title('Sexy Icon Entry Test');
$window->set_border_width(12);

$window->signal_connect(destroy => sub { Gtk2->main_quit });

my $table = Gtk2::Table->new(2, 4, FALSE);
$table->show();
$window->add($table);
$table->set_row_spacings(6);
$table->set_col_spacings(6);

# Open File
my $label1 = Gtk2::Label->new('Open File:');
$label1->show();
$table->attach($label1, 0, 1, 0, 1, 'fill', 'fill', 0, 0);
$label1->set_alignment(0.0, 0.5);

my $icon_entry1 = Gtk2::Sexy::IconEntry->new();
$icon_entry1->show();
$table->attach($icon_entry1, 1, 2, 0, 1, [qw(fill expand)], 'fill', 0, 0);

my $icon1 = Gtk2::Image->new_from_stock('gtk-open', 'menu');
$icon1->show();
$icon_entry1->set_icon('primary', $icon1);
$icon_entry1->set_icon_highlight('primary', TRUE);

# Save File
my $label2 = Gtk2::Label->new('Save File:');
$label2->show();
$table->attach($label2, 0, 1, 1, 2, 'fill', 'fill', 0, 0);
$label2->set_alignment(0.0, 0.5);

my $icon_entry2 = Gtk2::Sexy::IconEntry->new();
$icon_entry2->show();
$table->attach($icon_entry2, 1, 2, 1, 2, [qw(fill expand)], 'fill', 0, 0);
$icon_entry2->set_text('‏Right-to-left');
$icon_entry2->set_direction('rtl');

my $icon2 = Gtk2::Image->new_from_stock('gtk-save', 'menu');
$icon2->show();
$icon_entry2->set_icon('primary', $icon2);
$icon_entry2->set_icon_highlight('primary', TRUE);

# Search
my $label3 = Gtk2::Label->new('Search:');
$label3->show();
$table->attach($label3, 0, 1, 2, 3, 'fill', 'fill', 0, 0);
$label3->set_alignment(0.0, 0.5);

my $icon_entry3 = Gtk2::Sexy::IconEntry->new();
$icon_entry3->show();
$table->attach($icon_entry3, 1, 2, 2, 3, [qw(fill expand)], 'fill', 0, 0);
$icon_entry3->add_clear_button();

my $icon3 = Gtk2::Image->new_from_stock('gtk-find', 'menu');
$icon3->show();
$icon_entry3->set_icon('primary', $icon3);

# Password
my $label4 = Gtk2::Label->new('Password:');
$label4->show();
$table->attach($label4, 0, 1, 3, 4, 'fill', 'fill', 0, 0);
$label4->set_alignment(0.0, 0.5);

my $icon_entry4 = Gtk2::Sexy::IconEntry->new();
$icon_entry4->show();
$table->attach($icon_entry4, 1, 2, 3, 4, [qw(fill expand)], 'fill', 0, 0);
$icon_entry4->set_visibility(FALSE);

my $icon4 = Gtk2::Image->new_from_stock('gtk-authentication', 'menu');
$icon4->show();
$icon_entry4->set_icon('primary', $icon4);

Gtk2->main;
