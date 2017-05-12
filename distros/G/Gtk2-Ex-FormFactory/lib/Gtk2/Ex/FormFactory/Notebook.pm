package Gtk2::Ex::FormFactory::Notebook;

use strict;

use base qw( Gtk2::Ex::FormFactory::Container );

sub get_type { "notebook" }

sub object_to_widget {
	my $self = shift;

        my $page = $self->get_object_value;

        if ( defined $page ) {
            #-- the page widget must be visible, otherwise
            #-- it can't be selected
            my $page_widget = $self->get_gtk_widget->get_nth_page($page);
            $page_widget->show;
            
            #-- now set the page
    	    $self->get_gtk_widget->set ( page => $page );
        }

	1;
}

sub widget_to_object {
	my $self = shift;
	
	$self->set_object_value ($self->get_gtk_widget->get ("page"));
	
	1;
}

sub connect_changed_signal {
	my $self = shift;
	
	$self->get_gtk_widget->signal_connect_after (
	    'switch-page' => sub {
                $self->widget_value_changed;
            },
	);
	
	1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::Notebook - A Notebook in a FormFactory framework

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::Notebook->new (
    ...
    Gtk2::Ex::FormFactory::Container attributes
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This class implements a Notebook in a Gtk2::Ex::FormFactory framework.
The number of the actually selected notebook page is controlled by the
value of the associated application object attribute.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::Container
       +--- Gtk2::Ex::FormFactory::Notebook

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

Only widgets which have a B<title> attribute may be added to a
NoteBook. Since Gtk2::Ex::FormFactory::Container defines the
B<title> attribute all containers can be turned into a notebook page.

The widget title will automatically render to the title of the page
resp as the text appearing on the page's tab.

You can add an icon to the Notebook tab by prefixing the widget
title with a stock item name in square brackets, e.g. this way:

  title => "[gtk-cdrom] CDROM Contents",

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
