package Gapp::Layout;
{
  $Gapp::Layout::VERSION = '0.60';
}
use strict;
use warnings;

use Gapp::Layout::Object;

use Sub::Exporter -setup => {
    exports => [qw/Layout build add to extends paint style/],
    groups  => { default => [qw/Layout build add to extends paint style/] },
};

{
    my %Layouts;

    sub Layout {
        my $caller = shift;
        return $Layouts{$caller} ||= Gapp::Layout::Object->new;
    }
}



sub add {
    my ( $widget, @args ) = @_;
    caller()->Layout->add_packer( $widget, @args );
}


sub build {
    my ( $type, $definition ) = @_;
    caller()->Layout->add_builder( $type => $definition );
}

sub extends {
    my ( $base ) = @_;
    caller()->Layout->set_parent( $base->Layout );
}

sub paint {
    my ( $type, $definition ) = @_;
    caller()->Layout->add_painter( $type => $definition );
}

sub style {
    my ( $type, $definition ) = @_;
    caller()->Layout->add_styler( $type => $definition );
}

sub to {
    my ( $container, @args ) = @_;
    return ( $container, @args );
}



1;




__END__

=pod

=head1 NAME

Gapp::Layout - Define how widgets are displayed

=head1 SYNOPSIS

    package My::Custom::Layout;

    use Gapp::Layout;

    extends 'Gapp::Layout::Default';


    # center all entry texts

    style 'Gapp::Entry', sub {

        ( $layout, $widget ) = @_;

        $widget->properties->{xalign} ||= .5 ;

        $layout->parent->style_widget( $widget );

    };
    
    # add a widget to bottom of all vboxes
    build 'Gapp::VBox', sub {

        ( $layout, $widget ) = @_;

        $footer  = Gtk2::Label->new( 'footer!, 0, 0, 0 );

        $widget->gobject->pack_end( $footer,  );

        $layout->parent->build_widget( $widget );

    };
    
    # specify how buttons are packed into a button box
    add 'Gapp::Button', to 'Gapp::HButtonBox', sub {

        my ($l, $w, $c) = @_;

        $c->gobject->pack_end(

            $w->gobject,
    
            $w->expand,
    
            $w->fill,
    
            $w->padding
    
        );
    };
  
=head1 DESCRIPTION

L<Gapp::Layout> is a I<library for building layouts>. Creating a layout allows
you to customize the appearance of your widgets across your program in one
place. This also has the effect of keeping your gui design, application code,
and data structures separate.

Layouts are sub-classable and provide fine grained control of your program
apearance with a simple interface.

=head1 CREATING A LAYOUT

A layout is defined in a package. It is recomended that you inherit from
L<Gapp::Layout::Default>.
 
 package My::Custom::Layout;

 use Gapp::Layout;

 extends 'Gapp::Layout::Default';

 
=head2 Stylers

Stylers are used to alter any of the L<Gapp::Widget> attributes before the Gtk+
widget is constructed. The example below centers the the text in an entry field
if no xalign has been set. If you want to alter the Gtk+ widget once it has been
constructed, you want to use a builder.

  # center all entry texts
  style 'Gapp::Entry', sub {

    ( $layout, $widget ) = @_;

    $widget->{properties}{xalign} if ! defined $widget->{properties}{xalign};

    $layout->parent->style_widget( $widget );

  };

=head2 Builders

Builders are used to customize the Gtk+ widget once it is has been. Use the
builder to maniplulate things at the Gtk2 level.

    # add a widget to bottom of all vboxes
    build 'Gapp::VBox', sub {

        ( $layout, $widget ) = @_;

        $footer  = Gtk2::Label->new( 'footer!, 0, 0, 0 );

        $widget->gobject->pack_end( $footer,  );

        $layout->parent->build_widget( $widget );

    };

=head2 Packers

Packers are used to position widgets in containers. 

    # specify how buttons are packed into a button box

    add 'Gapp::Button', to 'Gapp::HButtonBox', sub {

        my ( $layout, $widget, $container ) = @_;

        $container->gobject->pack_end(

            $widget->gobject,

            $widget->expand,

            $widget->fill,

            $widget->padding

        );

    };
    
The example above defines the packing rules for a very specific case - how a L<Gapp::Button>
is packed into a L<Gapp::HbuttonBox>, but you can define something much more general.
The example below demonstrates a more general use packing rule, determining how an L<Gapp::Widget>
should be displayed in a L<Gapp::VBox>. 

    # widgets always fill/expand vboxes

    add 'Gapp::Widget', to 'Gapp::VBox', sub {

        my ( $layout, $widget, $container ) = @_;

        $container->gobject->pack_end(

            $widget->gobject,

            $widget->expand,

            $widget->fill,

            $widget->padding

        );

    };

This will make any L<Gapp::Widget> in a L<Gapp::VBox> expand and fill. You could
then override this, for a specific widget:

    # widgets always fill/expand vboxs

    add 'Gapp::Widget', to 'Gapp::VBox', sub {

        my ( $layout, $widget, $container ) = @_;

        $container->gobject->pack_end(

            $widget->gobject,

            1,

            1, #fill

            $widget->padding

        );

    };

=head1 EXPORTED FUNCTIONS

=over 4

=item B<add $widget_class, to $widget_class, \&add_func >

Set the packer for this widget\container combination.

=item B<build $widget_class, \&build_func >

Set the builder for this widget.

=item B<extends $layout_class>

Use this if you want to subclass another layout.

=item B<style $widget_class, \&style_func >

Set the styler for this widget.

=back

=head1 AUTHOR

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.
    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut


