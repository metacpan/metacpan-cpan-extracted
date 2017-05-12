package Gtk2::Ex::FormFactory::ProgressBar;

use strict;

use base qw( Gtk2::Ex::FormFactory::Widget );

sub get_type { "progress_bar" }

sub object_to_widget {
	my $self = shift;

	my $status           = $self->get_object_value;
	my $gtk_progress_bar = $self->get_gtk_widget;

	$gtk_progress_bar->set_fraction ($status->{fraction});
	$gtk_progress_bar->set_text     ($status->{text});

	1;
}

sub empty_widget {
	my $self = shift;
	
	my $gtk_progress_bar = $self->get_gtk_widget;

	$gtk_progress_bar->set_fraction (0);
	$gtk_progress_bar->set_text     ("");
	
	1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::ProgressBar - A ProgressBar in a FormFactory framework

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::ProgressBar->new (
    ...
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This class implements a ProgressBar in a Gtk2::Ex::FormFactory framework.
The state of the progress bar is the value of the associated application
object attribute.

This value must be a hash reference defining these keys:

=over 10

=item B<fraction>

A float value between 0.0 and 1.0 representing the length of the
progress bar.

=item B<text>

An optional text displayed in the progress bar.

=back

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::ProgressBar

  Gtk2::Ex::FormFactory::Layout
  Gtk2::Ex::FormFactory::Rules
  Gtk2::Ex::FormFactory::Context
  Gtk2::Ex::FormFactory::Proxy

=head1 ATTRIBUTES

This module has no additional attributes over those derived
from Gtk2::Ex::FormFactory::Widget.

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
