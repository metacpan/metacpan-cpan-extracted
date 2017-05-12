package Gtk2::Ex::FormFactory::Image;

use strict;

use base qw( Gtk2::Ex::FormFactory::Widget );

sub get_type { "image" }

sub get_with_frame		{ shift->{with_frame}			}
sub get_bgcolor			{ shift->{bgcolor}			}
sub get_scale_to_fit		{ shift->{scale_to_fit}			}
sub get_max_width		{ shift->{max_width}			}
sub get_max_height		{ shift->{max_height}			}
sub get_widget_width		{ shift->{widget_width}			}
sub get_widget_height		{ shift->{widget_height}		}
sub get_scale			{ shift->{scale}			}
sub get_scale_hook		{ shift->{scale_hook}			}
sub get_gtk_event_box		{ shift->{gtk_event_box}		}

sub set_with_frame		{ shift->{with_frame}		= $_[1]	}
sub set_bgcolor			{ shift->{bgcolor}		= $_[1]	}
sub set_scale_to_fit		{ shift->{scale_to_fit}		= $_[1]	}
sub set_max_width		{ shift->{max_width}		= $_[1]	}
sub set_max_height		{ shift->{max_height}		= $_[1]	}
sub set_widget_width		{ shift->{widget_width}		= $_[1]	}
sub set_widget_height		{ shift->{widget_height}	= $_[1]	}
sub set_scale			{ shift->{scale}		= $_[1]	}
sub set_scale_hook		{ shift->{scale_hook}		= $_[1]	}
sub set_gtk_event_box		{ shift->{gtk_event_box}	= $_[1]	}

sub get_gtk_signal_widget {
	shift->get_gtk_event_box;
}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($with_frame, $bgcolor, $scale_to_fit, $max_width) =
	@par{'with_frame','bgcolor','scale_to_fit','max_width'};
	my  ($max_height, $scale, $scale_hook) =
	@par{'max_height','scale','scale_hook'};

	my $self = $class->SUPER::new(@_);

	$scale ||= 1 unless $scale_to_fit || $scale_hook;

	$self->set_with_frame($with_frame);
	$self->set_bgcolor($bgcolor);
	$self->set_scale_to_fit($scale_to_fit);
	$self->set_max_width($max_width);
	$self->set_max_height($max_height);
	$self->set_scale($scale);
	$self->set_scale_hook($scale_hook);
	
	return $self;
}

sub object_to_widget {
	my $self = shift;

	my $filename   = $self->get_object_value;
	return $self->empty_widget unless $filename and -r $filename;

	my $gtk_image  = $self->get_gtk_widget;
	my $gtk_pixbuf = Gtk2::Gdk::Pixbuf->new_from_file($filename);

	my $scale_to_fit = $self->get_scale_to_fit;
	my $max_width    = $self->get_max_width;
	my $max_height   = $self->get_max_height;
	my $scale        = $self->get_scale;
	my $scale_hook   = $self->get_scale_hook;

	if ( defined $scale ) {
		my $image_width    = $gtk_pixbuf->get_width;
		my $image_height   = $gtk_pixbuf->get_height;

		if ( $scale == 1 ) {
			$gtk_image->set_from_pixbuf ( $gtk_pixbuf );
			$gtk_image->set_size_request ($image_width, $image_height);
			return 1;
		}

		my $new_width  = int($image_width  * $scale);	
		my $new_height = int($image_height * $scale);	
		return if $new_width <= 0 or $new_height <= 0;

		my $scaled_pixbuf = $gtk_pixbuf->scale_simple (
			$new_width, $new_height, "GDK_INTERP_BILINEAR"
		);

		$gtk_image->set_from_pixbuf ( $scaled_pixbuf );
		$gtk_image->set_size_request ($image_width, $image_height);

	} elsif ( $scale_hook ) {
		my $scale = &$scale_hook($self, $gtk_pixbuf);

		my $image_width    = $gtk_pixbuf->get_width;
		my $image_height   = $gtk_pixbuf->get_height;

		my $new_width  = int($image_width  * $scale);	
		my $new_height = int($image_height * $scale);	
		return if $new_width <= 0 or $new_height <= 0;

		my $scaled_pixbuf = $gtk_pixbuf->scale_simple (
			$new_width, $new_height, "GDK_INTERP_BILINEAR"
		);

		$gtk_image->set_from_pixbuf ( $scaled_pixbuf );

	} elsif ( $scale_to_fit or $max_width or $max_height ) {
		my $image_width    = $gtk_pixbuf->get_width;
		my $image_height   = $gtk_pixbuf->get_height;

		my $widget_width   = $self->get_widget_width;
		my $widget_height  = $self->get_widget_height;

		$widget_width  = $max_width  if defined $max_width and
						$max_width < $widget_width;
		$widget_height = $max_height if defined $max_height and
						$max_height < $widget_height;
		
		my $width_scale  = $widget_width  / $image_width;
		my $height_scale = $widget_height / $image_height;

		my $scale = $width_scale < $height_scale ?
			$width_scale : $height_scale;

		my $new_width  = int($image_width  * $scale);	
		my $new_height = int($image_height * $scale);	
		return if $new_width <= 0 or $new_height <= 0;

		my $scaled_pixbuf = $gtk_pixbuf->scale_simple (
			$new_width, $new_height, "GDK_INTERP_BILINEAR"
		);

		$gtk_image->set_from_pixbuf ( $scaled_pixbuf );

	} else {
		$gtk_image->set_from_pixbuf ( $gtk_pixbuf );
	}
	
	1;
}

sub empty_widget {
	my $self = shift;
	
	$self->get_gtk_widget->set_from_pixbuf(undef);
	
	1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::Image - An Image in a FormFactory framework

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::Image->new (
    bgcolor       => Background color of the widget,
    with_frame    => Draw a frame around the image?,
    scale_to_fit  => Automatially scale the image in its container?,
    max_width     => Maximum width the image may scale to,
    max_height    => Maximum height the image may scale to,
    scale         => Display the image with this constant scaling,
    scale_hook    => Callback which returns the actual scale,
    ...
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This class implements an Image in a Gtk2::Ex::FormFactory framework.
The image is always displayed with its natural aspect ratio, but
there are various possibilities to control the scaling of the image.

The value of the associated application object attribute is the
filename of the displayed image. The file format must be supported
by Gtk2::Gdk::PixBuf.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::Image

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

=item B<bgcolor> = "RGB Hex Triple" [optional]

This is the background color of the widget. If set all areas
of the widget not filled with the image are painted with this
color.

=item B<with_frame> = BOOL [optional]

If set to TRUE a frame is rendered around the image.

=item B<scale_to_fit> = BOOL [optional]

If set to TRUE the image will automatically scale proportionally
into to the space the container of this widget allocated for the
image widget.

=item B<max_width> = INTEGER [optional]

With this attribute you can define a maximm width the image may
scale to.

=item B<max_height> = INTEGER [optional]

With this attribute you can define a maximm height the image may
scale to.

=item B<scale> = FLOAT [optional]

If you set this attribute, no dynamic scaling applies, but the
image will be constantly scaled with this value. This overrides
all other attributes regarding dynamic scaling.

=item B<scale_hook> = CODEREF(FormFactory::Image, PixBuf) [optional]

This code reference is called if the image needs an update
e.g. if the associated application object attribute changed or
the parent was resized and B<scale_to_fit> was set.

The Gtk2::Ex::FormFactory::Image instance and the Gtk2::Gdk::PixBuf
of the image are passed to the function.

If B<scale_to_fit> is set the widget's dimension are tracked
automatically. The actual width and height are stored in the
attributes B<widget_width> and B<widget_height> and thus can
be accessed from the callback by calling B<get_widget_width>
and B<get_widget_width>.

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
