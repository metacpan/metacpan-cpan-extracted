package Gtk2::Ex::FormFactory::Popup;

use strict;

use base qw( Gtk2::Ex::FormFactory::Widget );

sub get_type { "popup" }

sub get_items			{ shift->{items}			}
sub set_items			{ shift->{items}		= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my ($items) = $par{'items'};

	my $self = $class->SUPER::new(@_);
	
	$self->set_items($items);
	
	return $self;
}


sub object_to_widget {
	my $self = shift;

	my $content = $self->get_items ||
		      $self->get_proxy->get_attr_list($self->get_attr, $self->get_name);
	my $value   = $self->get_object_value;

	my $gtk_popup      = $self->get_gtk_widget;
	my $gtk_popup_menu =  Gtk2::Menu->new;

	$gtk_popup->remove_menu;
	$gtk_popup->set_menu($gtk_popup_menu);

	my ($history, $i);
	if ( ref $content eq 'ARRAY' ) {
		my ($item);
		$history = $i = 0;
		foreach my $text ( @{$content} ) {
			if ( ref $text eq 'ARRAY' ) {
				$item = Gtk2::MenuItem->new ($text->[1]);
				$item->show;
				$item->{value} = $text->[0];
				$gtk_popup_menu->append($item);
				$history = $i if $text->[0] eq $value;
			} else {
				$item = Gtk2::MenuItem->new ($text);
				$item->show;
				$item->{value} = $i;
				$gtk_popup_menu->append($item);
				$history = $i if $i == $value;
			}
			++$i;
		}
	} else {
		my (@content, $k, $v);
		push @content, [ $k, $v ] while ($k,$v) = each %{$content};
		my ($item);
		$history = $i = 0;
		foreach my $c ( sort { $a->[1] cmp $b->[1] } @content ) {
			$item = Gtk2::MenuItem->new ($c->[1]);
			$item->show;
			$item->{value} = $c->[0];
			$gtk_popup_menu->append($item);
			$history = $i if $value eq $c->[0];
			++$i;
		}
	}

	$gtk_popup->set_history ($history);

	1;
}

sub widget_to_object {
	my $self = shift;
	
	$self->set_object_value (
		$self->get_gtk_widget->get_menu->get_active->{value}
	);
	
	1;
}

sub get_widget_value {
	my $self = shift;
	return $self->get_gtk_widget->get_menu->get_active->{value};
}

sub empty_widget {
	my $self = shift;

	my $gtk_popup      = $self->get_gtk_widget;
	my $gtk_popup_menu =  Gtk2::Menu->new;

	$gtk_popup->remove_menu;
	$gtk_popup->set_menu($gtk_popup_menu);

	my $item = Gtk2::MenuItem->new ("          ");
	$item->show;
	$gtk_popup_menu->append($item);
	$gtk_popup->set_history ( 0 );
	
	1;
}

sub backup_widget_value {
	my $self = shift;
	
	$self->set_backup_widget_value (
		$self->get_gtk_widget->get_history
	);
	
	1;
}

sub restore_widget_value {
	my $self = shift;
	
	$self->get_gtk_widget->set_history($self->get_backup_widget_value);
	
	1;
}

sub get_widget_check_value {
	$_[0]->get_gtk_widget->get_menu->get_active->{value};
}

sub connect_changed_signal {
	my $self = shift;

	$self->get_gtk_widget->signal_connect (
	  changed => sub { $self->widget_value_changed },
	);
	
	1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::Popup - A Popup in a FormFactory framework

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::Popup->new (
    ...
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This class implements a Popup in a Gtk2::Ex::FormFactory framework.
The selected entry of the Popup is controlled by the value of the
associated application object attribute, which is either an index in
an array of possible Popup entries or a key of a hash of possible
Popup entries.

Refer to the chapter REQUIREMENTS FOR ASSOCIATED APPLICATION OBJECTS
for details.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::Popup

  Gtk2::Ex::FormFactory::Layout
  Gtk2::Ex::FormFactory::Rules
  Gtk2::Ex::FormFactory::Context
  Gtk2::Ex::FormFactory::Proxy

=head1 ATTRIBUTES

Attributes are handled through the common get_ATTR(), set_ATTR()
style accessors, but they are mostly passed once to the object
constructor and must not be altered after the associated FormFactory
was built.

=over 4

=item B<items> = ARRAYREF|HASHREF [optional]

This attribute takes a static list of popup items, if the
popup shouldn't be controlled dynamically by an associated
application object. Refer to the next chapter for details
of the data structure applied here.

=back

=head1 REQUIREMENTS FOR ASSOCIATED APPLICATION OBJECTS

Application objects represented by a Gtk2::Ex::FormFactory::Popup
must define additional methods, unless their content is static
by setting B<items>.

The naming of the methods listed beyond uses the standard
B<get_> prefix for the attribute read accessor. B<ATTR> needs to
be replaced by the actual name of the attribute associated with
the widget.

=over 4

=item B<get_ATTR_list>

This returns the entries of the Popup. Three data models are supported here:

=over 7

=item Simple B<ARRAY>

If the method returns a reference to a simple array, the popup will be filled
with the array values in the original array order.

The index of the actually selected popup entry is stored in the
attribute of the associated application object.

=item Two dimensional B<ARRAY>

The method may return a reference to a two dimensional array. Each row needs to
have the attribute value in the first column and the label for the corresponding
item in the second.

=item B<HASH>

If the method returns a reference to a hash, the popup will be filled
with the alphanumerically sorted hash B<values>.

In turn the hash B<key> of the actually selected popup entry is stored in the
attribute of the associated application object.

=back

=back

=head1 AUTHORS

 Jörn Reder <joern at zyn dot de>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2006 by Jörn Reder.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Library General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307
USA.

=cut
