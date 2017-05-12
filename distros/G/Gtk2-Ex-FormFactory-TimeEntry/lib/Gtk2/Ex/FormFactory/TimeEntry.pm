package Gtk2::Ex::FormFactory::TimeEntry;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:JHALLOCK';

use strict;
use base qw( Gtk2::Ex::FormFactory::Widget );

use Gtk2::Ex::TimeEntry;
sub get_type { "time_entry" }

sub object_to_widget {
    my $self = shift;
    $self->get_gtk_widget->set_value($self->get_object_value);
    1;
}

sub widget_to_object {
    my $self = shift;
    $self->set_object_value($self->get_gtk_widget->get_value);
    1;
}

sub empty_widget {
    my $self = shift;
    $self->get_gtk_widget->set_value(undef);
    1;
}

sub backup_widget_value {
    my $self = shift;
    $self->set_backup_widget_value ($self->get_gtk_widget->get_value);
    1;
}

sub restore_widget_value {
    my $self = shift;
    $self->get_gtk_widget->set_value($self->get_backup_widget_value);
    1;
}

sub get_widget_check_value {
    $_[0]->get_gtk_widget->get_value;
}

sub connect_changed_signal {
	my $self = shift;

	$self->get_gtk_widget->signal_connect (
	  'value-changed' => sub { $self->widget_value_changed },
	);
	
	1;
}


package Gtk2::Ex::FormFactory::Layout;

sub build_time_entry {
	my $self = shift;
	my ($entry) = @_;
	
	my $gtk_entry = Gtk2::Ex::TimeEntry->new;
	$entry->set_gtk_widget($gtk_entry);
	
	1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::DateEntry - A Gtk2::Ex::DateEntry in a FormFactory framework

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::TimeEntry->new (
    ...
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This class implements a Gtk2::Ex::TimeEntry in a Gtk2::Ex::FormFactory
framework. The content of the Entry is the value of the associated application
object attribute.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::TimeEntry

  Gtk2::Ex::FormFactory::Layout
  Gtk2::Ex::FormFactory::Rules
  Gtk2::Ex::FormFactory::Context
  Gtk2::Ex::FormFactory::Proxy

=head1 ATTRIBUTES

This module has no additional attributes over those derived
from Gtk2::Ex::FormFactory::Widget. 

=head1 SEE ALSO

L<Gtk2::Ex::TimeEntry>
L<Gtk2::Ex::DateEntry>
L<Gtk2::Ex::FormFactory>
L<Gtk2::Ex::FormFactory::DateEntry>

=head1 AUTHOR

Jeffrey Ray Hallock <jeffrey at jeffrey.ray dot info>

=head1 BUGS

None known. Please send bugs to < jeffrey at jeffrey.ray dot info >.
Patches and suggestions welcome.

=head1 LICENSE

Gtk2-Ex-FormFactory-TimeEntry is Copyright 2010 Jeffrey Ray Hallock

Gtk2-Ex-FormFactory-TimeEntry is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-FormFactory-TimeEntry is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-FormFactory-DateEntry.  If not, see L<http://www.gnu.org/licenses/>.

=cut
