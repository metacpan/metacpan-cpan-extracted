package Gtk2::Ex::FormFactory::Form;

use strict;

use base qw( Gtk2::Ex::FormFactory::Container );

sub get_type { "form" }

sub get_label_top_align         { shift->{label_top_align}              }
sub set_label_top_align         { shift->{label_top_align}      = $_[1] }

sub new {
	my $class = shift;
	my %par = @_;
	my ($label_top_align) = $par{'label_top_align'};

	my $self = $class->SUPER::new(@_);
	
	$self->set_label_top_align($label_top_align);
	
	return $self;
}



1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::Form - A Form in a FormFactory framework

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::Form->new (
    label_top_align         => Align all labels at the top of their row,
    ...
    Gtk2::Ex::FormFactory::Container attributes
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This class implements a Form in a Gtk2::Ex::FormFactory framework.
A Form is rendered as a two column table with labels in the first
and the corresponding widgets in the second column. No application
object attributes are associated with a Form.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::Container
       +--- Gtk2::Ex::FormFactory::Form

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

=item B<label_top_align> = BOOLEAN [optional]

If you set this option all form element lables are aligned to
the top of their row. By default labels are centered vertically.

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
