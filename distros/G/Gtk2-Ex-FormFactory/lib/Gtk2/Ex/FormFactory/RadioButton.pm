package Gtk2::Ex::FormFactory::RadioButton;

use strict;

use base qw( Gtk2::Ex::FormFactory::Widget );

sub get_type	{ "radio_button" }
sub has_label	{ 1 }

sub get_value			{ shift->{value}			}
sub set_value			{ shift->{value}		= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my ($value) = $par{'value'};

	my $self = $class->SUPER::new(@_);
	
	$self->set_value($value);
	
	return $self;
}

sub object_to_widget {
	my $self = shift;

	$self->get_gtk_widget->set_active (1)
		if $self->get_object_value eq $self->get_value;

	1;
}

sub widget_to_object {
	my $self = shift;
	
	if ( $self->get_gtk_widget->get_active ) {
		$self->set_object_value ($self->get_value);
	}
	
	1;
}

sub backup_widget_value {
	my $self = shift;
	
	$self->set_backup_widget_value ($self->get_gtk_widget->get_active ? 1 : 0);
	
	1;
}

sub restore_widget_value {
	my $self = shift;
	
	$self->get_gtk_widget->set_active($self->get_backup_widget_value);
	
	1;
}

sub get_widget_check_value {
	$_[0]->get_gtk_widget->get_active ? $_[0]->get_value : undef;
}

sub connect_changed_signal {
	my $self = shift;
	
	$self->get_gtk_widget->signal_connect (
	  "released" => sub { $self->widget_value_changed }
	);
	
	1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::RadioButton - A RadioButton in a FormFactory framework

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::RadioButton->new (
    value => Value this RadioButton sets in the associated
             application object attribute,
    ...
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This class implements a RadioButton in a Gtk2::Ex::FormFactory framework.
The activation state of the RadioButton is controlled by the value of
the associated application object attribute.

All RadioButton's which should be grouped together need to be added
to the same container resp. they must have the same parent.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::RadioButton

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

=item B<value> = SCALAR [optional]

This value is transferred to the attribute of the associated
application object when the RadioButton is activated.

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
