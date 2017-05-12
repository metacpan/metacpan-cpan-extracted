package Gtk2::GladeXML::Simple;

use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;
use Gtk2::GladeXML;

our $VERSION = '0.32';

sub new {
    my ( $caller, $gladefile, $root, $domain ) = @_;
    croak "You need to specify a glade file first" unless $gladefile;
    my $self = bless {}, ref( $caller ) || $caller;
    Gtk2::Glade->set_custom_handler( sub{ $self->_custom_handler( @_ ) } );
    $self->{xml} = Gtk2::GladeXML->new( $gladefile, $root, $domain );
    $self->_signal_autoconnect_simple;
    $self->_get_widgets;
    return $self;
}

sub glade_object {
    my ( $self ) = @_;
    return $self->{xml};
}

sub get_widget {
    my ( $self, $widget ) = @_;
    return $self->{$widget};
}

sub get_widgets {
    my ( $self ) = @_;
    return $self->glade_object->get_widget_prefix( '' );
}

sub run {
    my ( $self ) = @_;
    Gtk2->main;
}

sub _get_widgets {
    my ( $self ) = @_;
    $self->{ $_->get_widget_name } = $_ foreach $self->get_widgets;
}

sub _custom_handler {
    my ( $self, $xml, $func_name, $name, $str1, $str2, $int1, $int2 ) = @_;
    $self->$func_name( $str1, $str2, $int1, $int2 );
}

sub _signal_autoconnect_simple {
    my ( $self ) = @_;
    $self->glade_object->signal_autoconnect( \&_autoconnect_helper, $self );
}

sub _autoconnect_helper {
    my ( $handler_name, $object, $signal_name, $signal_data,
	 $connect_object, $is_after, $self ) = @_;

    my $connect_func = $is_after ? 'signal_connect_after' : 'signal_connect';
    $object->$connect_func( $signal_name,
			    sub { $self->$handler_name( @_ ) },
			    $signal_data );
}

1;
__END__

=head1 NAME

Gtk2::GladeXML::Simple - A clean object-oriented interface to Gtk2::GladeXML

=head1 SYNOPSIS

   package MyApp;
   use base qw( Gtk2::GladeXML::Simple );

   sub new {
      my $class = shift;
      my $self = $class->SUPER::new( $gladefile );
      return $self;
   }

   ...

   # Signal handlers are methods of your class
   sub on_button_clicked {
      my $self = shift;
      # You have access to your widgets directly
      # or using $self->get_widget( widget_name )
      my $button = $self->{button1};
   }

=head1 DESCRIPTION

Gtk2::GladeXML::Simple is a module that provides a clean and easy interface
for Gnome/Gtk2 and Glade applications using an object-oriented syntax. You just
make Gtk2::GladeXML::Simple your application's base class, have your C<new> call
C<SUPER::new>, and the module will do the tedious and dirty work for you.

Gtk2::GladeXML::Simple offers:

=over

=item *

Signal handler callbacks as methods of your class.

   sub on_button1_clicked {
      my $self = shift; # $self always received as first parameter
      ...
      # do anything you want in a OO fashioned way
   }

=item *

Autoconnection of signal handlers.

=item *

Autocalling of creation functions for custom widgets.

=item *

Access to the widgets as instance attributes.

   my $btn = $self->{button1}; # fetch widgets as instance attributes by their names
   my $window = $self->{main_window};
   my $custom = $self->{custom_widget};

=back


=head1 METHODS

This class provides the following public methods:

=over

=item new( $gladefile I<[, $root, $domain ]> );

This method creates a new object of your subclass of Gtk2::GladeXML::Simple.
The C<$gladefile> parameter is the name of the file created by the Glade Visual Editor.
The C<$root> is an optional parameter that tells C<libglade> the name of the widget
to start building from. The optional C<$domain> parameter that specifies the translation
domain for the glade xml file ( undef by default ).

=item glade_object

This method returns the Gtk2::GladeXML object in play.

=item get_widget( $widget_name )

Returns the widget with given name. Same as calling $self->{$widget_name}.

=item get_widgets

Returns a list with all the widgets in the glade file.

=item run

Call this method in order to run your application. If you need another event loop
rather than the Gtk one, override I<run> in your class with your event loop (for
example the GStreamer event loop).

=back

=head1 EXTENDED EXAMPLE

This example shows the usage of the module by creating a small Yahoo search
engine using WWW::Search::Yahoo.

   package YahooApp;

   use strict;
   use warnings;
   use Gtk2 '-init';
   use Gtk2::Html2; #not part of the Gtk2 core widgets
   use Gtk2::GladeXML::Simple;
   use WWW::Search;

   use base qw( Gtk2::GladeXML::Simple );

   my $header =<<HEADER;
   <html>
   <meta HTTP-EQUIV="content-type" CONTENT="text/html; charset=UTF-8">
   <header><title>Yahoo Gtk2 App</title>
   <style type="text/css">
   .title {font-family: Georgia; color: blue; font-size: 13px}
   .description {padding-left: 3px; font-family: Georgia; font-size:10px}
   .url {padding-left: 3px; font-family: Georgia; font-size:10px; color: green}
   </style>
   </head>
   <body>
   <h2 style="font-family: Georgia, Arial; font-weight: bold">
   Found:
   </h2>
   HEADER

   my $footer =<<FOOTER;
   </body>
   </html>
   FOOTER

   sub new {
       my $class = shift;
       #Calling our super class constructor
       my $self = $class->SUPER::new( 'yahoo.glade' );
       #Initialize the search engine
       $self->{_yahoo} = WWW::Search->new( 'Yahoo' );
       return $self;
   }

   sub do_search {
       my $self = shift;
       $self->{_yahoo}->native_query( shift );
       my $buf = $header;
       for( 1..10 ) {
	   my $rv = $self->{_yahoo}->next_result || last;
	   $buf .= qq{<p><div class="title">} . $rv->title;
	   $buf .= qq{</div><br /><div class="description">} . $rv->description;
	   $buf .= qq{</div><br /><div class="url">} . $rv->url . q{</div></p><br />};
       }
       $buf .= $footer;
       $self->{buf} = $buf;
   }

   ### Signal handlers, now they're methods of the class ###
   sub on_Clear_clicked {
       my $self = shift;
       my $html = $self->{custom1}; #fetch widgets by their names
       $html->{document}->clear;
       my $statusbar = $self->{statusbar1}; #another widget
       $statusbar->pop( $statusbar->get_context_id( "Yahoo" ) );
   }

   sub on_Search_clicked {
       my $self = shift;
       my $text = $self->{text_entry}->get_text;
       return unless $text ne '';
       my $statusbar = $self->{statusbar1};
       $statusbar->push( $statusbar->get_context_id( "Yahoo" ), "Searching for: $text" );
       $self->do_search( $text );
       my $html = $self->{custom1};
       $html->{document}->clear;
       $html->{document}->open_stream( "text/html" );
       $html->{document}->write_stream( $self->{buf} );
       $html->{document}->close_stream;
   }

   ### Creation function for the custom widget, method of the class as well ###
   sub create_htmlview {
       my $self = shift;
       my $view = Gtk2::Html2::View->new;
       my $document = Gtk2::Html2::Document->new;
       $view->set_document( $document );
       $view->{document} = $document;
       $view->show_all;
       return $view;
   }

   sub gtk_main_quit { Gtk2->main_quit }

   1;

   package main;

   YahooApp->new->run; #Go!

   1;

The I<yahoo.glade> file needed for this example is in the I<examples> directory,
along with other example programs.

=head1 UTILITIES

=head2 Rapid Application Development with I<gpsketcher>

The Gtk2::GladeXML::Simple distribution includes I<gpsketcher>, a program that
generates Perl code stubs from glade XML files. The code stubs include the basic
framework for Gtk2::GladeXML::Simple interaction, method signatures, and everything
that describes the application itself. Developers must fill in the code stubs to
add the correct functionality to the application.

=head1 SEE ALSO

L<Gtk2::GladeXML>, L<Gtk2>, L<gpsketcher>

The Libglade Reference Manual at L<http://developer.gnome.org/doc/API/2.0/libglade/>

The gtk2 API Reference at L<http://developer.gnome.org/doc/API/2.0/gtk/index.html>

=head1 TODO

Tests.

More examples?

Add Gtk2::GladeXML::Simple::new_from_buffer()?

Support to I18N ( bindtextdomain )

=head1 AUTHOR

Marco Antonio Manzo <marcoam@perl.org.mx>

Special thanks in no order to Scott Arrington "muppet" <scott at asofyet dot org> who provided
lots of great ideas to improve this module. Sandino "tigrux" Flores <tigrux at ximian dot com>
who is the author of SimpleGladeApp and the main source of this module's core idea.
Sean M. Burke <sburke at cpan dot org> and Rocco Caputo <rcaputo at cpan dot org> for constantly
helping me with ideas and cleaning my POD.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Marco Antonio Manzo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
