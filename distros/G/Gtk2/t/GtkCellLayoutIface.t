#!/usr/bin/perl -w
# vim: set filetype=perl :

package CustomCellLayout;

use strict;
use warnings;
use Glib ':constants';
use Gtk2;

use Test::More;

use Glib::Object::Subclass
    Gtk2::Widget::,
    interfaces => [ qw(Gtk2::CellLayout) ],
    ;

sub PACK_START {
  my ($self, $cell, $expand) = @_;
  isa_ok ($self, __PACKAGE__);
  isa_ok ($cell, 'Gtk2::CellRenderer');
  is ($expand, TRUE);
}

sub PACK_END {
  my ($self, $cell, $expand) = @_;
  isa_ok ($self, __PACKAGE__);
  isa_ok ($cell, 'Gtk2::CellRenderer');
  is ($expand, FALSE);
}

sub CLEAR {
  my ($self) = @_;
  isa_ok ($self, __PACKAGE__);
}

sub ADD_ATTRIBUTE {
  my ($self, $cell, $attribute, $column) = @_;
  isa_ok ($self, __PACKAGE__);
  isa_ok ($cell, 'Gtk2::CellRenderer');
  is ($attribute, 'text');
  is ($column, 42);
}

sub SET_CELL_DATA_FUNC {
  my ($self, $cell, $func, $data) = @_;
  isa_ok ($self, __PACKAGE__);
  isa_ok ($cell, 'Gtk2::CellRenderer');
  if (defined $func) {
    isa_ok ($func, 'Gtk2::CellLayout::DataFunc');
    ok (defined $data);

    my $model = Gtk2::ListStore->new (qw/Glib::String/);
    $func->($self, $cell, $model, $model->append (), $data);
  }
}

sub CLEAR_ATTRIBUTES {
  my ($self, $cell) = @_;
  isa_ok ($self, __PACKAGE__);
  isa_ok ($cell, 'Gtk2::CellRenderer');
}

sub REORDER {
  my ($self, $cell, $position) = @_;
  isa_ok ($self, __PACKAGE__);
  isa_ok ($cell, 'Gtk2::CellRenderer');
  is ($position, 42);
}

sub grow_the_stack { 0 .. 500 };

sub GET_CELLS {
  my ($self) = @_;
  isa_ok ($self, __PACKAGE__);
  $self->{cell_one} = Gtk2::CellRendererText->new;
  $self->{cell_two} = Gtk2::CellRendererToggle->new;
  my @list = grow_the_stack();
  return ($self->{cell_one}, $self->{cell_two});
}

package main;

use strict;
use warnings;
use Glib ':constants';
use Gtk2::TestHelper tests => 31;

my $cell = Gtk2::CellRendererText->new ();

my $layout = CustomCellLayout->new ();
$layout->pack_start ($cell, TRUE);
$layout->pack_end ($cell, FALSE);
$layout->clear ();
$layout->add_attribute ($cell, text => 42);
$layout->clear_attributes ($cell);
$layout->reorder ($cell, 42);

SKIP: {
  skip 'get_cells', 4
    unless Gtk2->CHECK_VERSION (2, 12, 0);

  my @cells = $layout->get_cells ();
  is (scalar @cells, 2);
  isa_ok ($cells[0], 'Gtk2::CellRendererText');
  isa_ok ($cells[1], 'Gtk2::CellRendererToggle');
}

my $callback = sub {
  my ($cb_layout, $cb_cell, $model, $iter, $data) = @_;
  is ($cb_layout, $layout);
  is ($cb_cell, $cell);
  isa_ok ($model, 'Gtk2::ListStore');
  isa_ok ($iter, 'Gtk2::TreeIter');
  is ($data, 'bla!');
};
$layout->set_cell_data_func ($cell, $callback, 'bla!');
$layout->set_cell_data_func ($cell, undef);
