package Gtk2::Ex::FormFactory::GtkWidget;

use strict;

use base qw( Gtk2::Ex::FormFactory::Widget );

sub get_custom_gtk_widget	{ shift->{custom_gtk_widget}		}
sub set_custom_gtk_widget	{ shift->{custom_gtk_widget}	= $_[1]	}

sub get_type { "gtk_widget" }

sub new {
	my $class = shift;
	my %par = @_;
	my ($custom_gtk_widget) = $par{'custom_gtk_widget'};

	my $self = $class->SUPER::new(@_);
	
	$self->set_custom_gtk_widget($custom_gtk_widget);
	
	return $self;
}

sub cleanup {
	my $self = shift;
	
	$self->SUPER::cleanup(@_);
	$self->set_custom_gtk_widget(undef);

	1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::GtkWidget - Wrap arbitrary Gtk widgets

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::GtkWidget->new (
    custom_gtk_widget => Gtk::Widget,
    ...
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

With this module you can add arbitrary Gtk widgets to a FormFactory.
They're simply displayed, but their state isn't managed by
Gtk2::Ex::FormFactory, because no details are known about the widget.

If you need the full functionality for a custom Gtk widget you need
to implement your own Gtk2::Ex::FormFactory::Widget for it. Refer to
the documentation of Gtk2::Ex::FormFactory::Widget for details
about implementing your own FormFactory widgets.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::GtkWidget

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

=item B<custom_gtk_widget> = Gtk::Widget [mandatory]

This is a Gtk::Widget to be displays inside a FormFactory.

=back

For more attributes refer to L<Gtk2::Ex::FormFactory::Widget>.

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
