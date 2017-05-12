package Gtk2::Ex::FormFactory::HBox;

use strict;

use base qw( Gtk2::Ex::FormFactory::Container );

sub get_type { "hbox" }

sub get_homogenous		{ shift->{homogenous}			}
sub get_spacing			{ shift->{spacing}			}
sub get_no_frame		{ shift->{no_frame}			}

sub set_homogenous		{ shift->{homogenous}		= $_[1]	}
sub set_spacing			{ shift->{spacing}		= $_[1]	}
sub set_no_frame		{ shift->{no_frame}		= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($homogenous, $spacing, $no_frame) =
	@par{'homogenous','spacing','no_frame'};

	my $self = $class->SUPER::new(@_);
	
	$self->set_homogenous($homogenous);
	$self->set_spacing($spacing);
	$self->set_no_frame($no_frame);

	return $self;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::HBox - A HBox in a FormFactory framework

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::HBox->new (
    homogenous => Bool,
    spacing    => Integer,
    no_frame   => Bool,
    ...
    Gtk2::Ex::FormFactory::Container attributes
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This class implements a HBox in a Gtk2::Ex::FormFactory framework.
No application object attributes are associated with a HBox.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::Container
       +--- Gtk2::Ex::FormFactory::HBox

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

=item B<homogenous> = BOOL [optional]

If set to TRUE all children in this HBox will have the same width.
This is a convenience attribute for the B<homogenous> property
of Gtk2::Box.

=item B<spacing> = INTEGER [optional]

The number of pixels between the child widgets in this HBox.
This is a convenience attribute for the B<spacing> property
of Gtk2::Box.

=item B<no_frame> = BOOL [optional]

By default a frame is added to the HBox if it has a B<title>.
Set B<no_frame> to a true value to supress this.

=back

For more attributes refer to Gtk2::Ex::FormFactory::Container.

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
