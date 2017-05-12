package Gtk2::Ex::FormFactory::Expander;

use strict;

use base qw( Gtk2::Ex::FormFactory::Container );

sub get_type 	{ "expander" 	}
sub has_label	{ 1		}

sub object_to_widget {
	my $self = shift;

	$self->get_gtk_widget->set_expanded($self->get_object_value);

	1;
}

sub widget_to_object {
	my $self = shift;
	
	$self->set_object_value ($self->get_gtk_widget->get_expanded);
	
	1;
}

sub backup_widget_value {
	my $self = shift;
	
	$self->set_backup_widget_value ($self->get_gtk_widget->get_expanded);
	
	1;
}

sub restore_widget_value {
	my $self = shift;
	
	$self->get_gtk_widget->set_expanded($self->get_backup_widget_value);
	
	1;
}

sub get_widget_check_value {
	$_[0]->get_gtk_widget->get_expanded;
}

sub connect_changed_signal {
	my $self = shift;

	$self->get_gtk_widget->signal_connect (
	  activate => sub { $self->widget_value_changed },
	);
	
	1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::Expander - An Expander in a FormFactory framework

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::Expander->new (
    ...
    Gtk2::Ex::FormFactory::Container attributes
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This class implements an Expander in a Gtk2::Ex::FormFactory framework.
The expansion state is controlled by the associated application
object attribute, which should has a boolean value.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::Container
       +--- Gtk2::Ex::FormFactory::Expander

  Gtk2::Ex::FormFactory::Layout
  Gtk2::Ex::FormFactory::Rules
  Gtk2::Ex::FormFactory::Context
  Gtk2::Ex::FormFactory::Proxy

=head1 ATTRIBUTES

This module has no additional attributes over those derived
from Gtk2::Ex::FormFactory::Container, but some special notes
apply:

=over 4

=item B<content> = ARRAYREF of Gtk2::Ex::FormFactory::Widget's [optional]

You may add only one child widget to this container.

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
