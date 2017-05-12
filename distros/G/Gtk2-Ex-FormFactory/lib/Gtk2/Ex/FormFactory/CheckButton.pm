package Gtk2::Ex::FormFactory::CheckButton;

use strict;

use base qw( Gtk2::Ex::FormFactory::Widget );

sub get_type { "check_button" }

sub get_detach_label		{ shift->{detach_label}			}
sub set_detach_label		{ shift->{detach_label}		= $_[1]	}

sub has_label			{ ! shift->get_detach_label }

sub new {
	my $class = shift;
	my %par = @_;
	my ($detach_label) = $par{'detach_label'};

	my $self = $class->SUPER::new(@_);
	
	$self->set_detach_label($detach_label);
	
	return $self;
}

sub object_to_widget {
	my $self = shift;
	
	$self->get_gtk_widget->set_active($self->get_object_value);

	1;
}

sub widget_to_object {
	my $self = shift;

	$self->set_object_value ($self->get_gtk_widget->get_active);

	1;
}

sub empty_widget {
	my $self = shift;
	
	$self->get_gtk_widget->set_active(0);
	
	1;
}

sub backup_widget_value {
	my $self = shift;
	
	$self->set_backup_widget_value ($self->get_gtk_widget->get_active);
	
	1;
}

sub restore_widget_value {
	my $self = shift;
	
	$self->get_gtk_widget->set_active($self->get_backup_widget_value);
	
	1;
}

sub get_widget_check_value {
	$_[0]->get_gtk_widget->get_active;
}

sub connect_changed_signal {
	my $self = shift;
	
	$self->get_gtk_widget->signal_connect (
	  toggled => sub { $self->widget_value_changed },
	);
	
	1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::CheckButton - A CheckButton in a FormFactory framework

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::CheckButton->new (
    detach_label => BOOL,
    ...
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This class implements a CheckButton in a Gtk2::Ex::FormFactory framework.
The state of the CheckButton is controlled by the associated application
object attribute, which should has a boolean value.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::CheckButton

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

=item B<detach_label> = BOOL [optional]

Set this to TRUE if the label of this checkbox should be managed
by the container (e.g. a Gtk2::Ex::FormFactory::Form) instead of
having the label beside the checkbox (which is the default).

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
