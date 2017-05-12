package Graphics::Primitive::Driver::CairoPango;
use Moose;
use Moose::Util::TypeConstraints;

use Cairo;
use Carp;
use Geometry::Primitive::Point;
use Geometry::Primitive::Rectangle;
use Graphics::Primitive::Driver::CairoPango::TextLayout;
use Pango;
use IO::File;
use Math::Trig ':pi';

extends 'Graphics::Primitive::Driver::Cairo';

# with 'Graphics::Primitive::Driver';

our $AUTHORITY = 'cpan:GPHAT';
our $VERSION = '0.63';

enum 'Graphics::Primitive::Driver::CairoPango::AntialiasModes' => [
    qw(default none gray subpixel)
];

enum 'Graphics::Primitive::Driver::CairoPango::Format' => [
    qw(PDF PS PNG SVG pdf ps png svg)
];

sub _draw_textbox {
    my ($self, $comp) = @_;

    return unless(defined($comp->text));

    my $context = $self->cairo;

    $context->save;
    $self->_draw_component($comp);
    $context->restore;

    my $bbox = $comp->inside_bounding_box;
    my $width = $bbox->width;

    $context->set_source_rgba($comp->color->as_array_with_alpha);

    my $origin = $bbox->origin;
    my $x = $origin->x;
    my $y = $origin->y;

    if(defined($comp->lines)) {
        my $start = $comp->lines->{start};
        my $count = $comp->lines->{count};
        my $endline = $start + $count;

        my $layout = $comp->layout->_layout;
        my $iter = $layout->get_iter;

        my $startpos = 0;

        my $line_index = 0;
        while($line_index < $endline) {
            if($line_index < $start) {
                $iter->next_line;
                $line_index++;
                next;
            }

            my $line = $iter->get_line_readonly;
            my ($ink, $log) = $iter->get_line_extents;
            my $baseline = $iter->get_baseline;

            if($start == $line_index) {
                $startpos = $log->{y} / 1024;
            }

            $context->move_to($x + ($log->{x} / 1024), $baseline / 1024 - $startpos + $y);

            Pango::Cairo::show_layout_line($context, $line);
            $line_index++;
            $iter->next_line;
        };
    } else {
        my $layout = $comp->layout->_layout;

        my $angle = $comp->angle;
        if($angle) {
            my $tw2 = $comp->width / 2;
            my $th2 = $comp->height / 2;

            $context->translate($tw2, $th2);
            $context->rotate($angle);
            $context->translate(-$tw2, -$th2);

            # Get the un-rotated extents so we can position it
            my ($ink, $log) = $layout->get_pixel_extents;
            $context->move_to(
                $tw2 - $log->{width} / 2,
                $th2 - $log->{height} / 2
            );
        } else {
            my ($ink, $log) = $layout->get_pixel_extents;
            if($comp->vertical_alignment eq 'bottom') {
                $y = $bbox->height - $log->{height} / 2;
            } elsif($comp->vertical_alignment eq 'center') {
                $y = $bbox->height / 2 - $log->{height} / 2;
            }
            $context->move_to($x, $y);
        }
        Pango::Cairo::update_layout($context, $layout);
        Pango::Cairo::show_layout($context, $layout);
    }
}

sub get_textbox_layout {
    my ($self, $comp) = @_;

    my $tl = Graphics::Primitive::Driver::CairoPango::TextLayout->new(
        component => $comp,
    );
    
    unless(defined($comp->text)) {
        $tl->height(0);
        return $tl;
    }

    my $context = $self->cairo;

    my $font = $comp->font;

    my $fontmap = Pango::Cairo::FontMap->get_default;

    my $desc = Pango::FontDescription->new;
    $desc->set_family($font->family);
    $desc->set_variant($font->variant);
    $desc->set_style($font->slant);
    $desc->set_weight($font->weight);
    $desc->set_size(Pango::units_from_double($font->size));

    my $layout = Pango::Cairo::create_layout($context);

    $layout->set_font_description($desc);
    $layout->set_markup($comp->text);
    $layout->set_indent(Pango::units_from_double($comp->indent));
    $layout->set_alignment($comp->horizontal_alignment);
    $layout->set_justify($comp->justify);
    if(defined($comp->wrap_mode)) {
        $layout->set_wrap($comp->wrap_mode);
    }
    if(defined($comp->ellipsize_mode)) {
        $layout->set_ellipsize($comp->ellipsize_mode);
    }

    if(defined($comp->line_height)) {
        $layout->set_spacing(Pango::units_from_double($comp->line_height - $comp->font->size));
    }

    my $pcontext = $layout->get_context;

    $fontmap->set_resolution(72);
    my $options = Cairo::FontOptions->create;
    $options->set_antialias($font->antialias_mode);
    $options->set_subpixel_order($font->subpixel_order);
    $options->set_hint_style($font->hint_style);
    $options->set_hint_metrics($font->hint_metrics);
    Pango::Cairo::Context::set_font_options($pcontext, $options);

    if(defined($comp->direction)) {
        $pcontext->set_base_dir($comp->direction);
    }

    my $width = $comp->width ? $comp->inside_width : $comp->minimum_inside_width;
    $width = -1 if(!defined($width) || ($width == 0));
    $layout->set_width(Pango::units_from_double($width));

    if($comp->height) {
        # $layout->set_height(Pango::units_from_double($comp->height));
    }

    if($comp->angle) {
        $context->save;

        my $tw2 = $comp->width / 2;
        my $th2 = $comp->height / 2;

        $context->translate($tw2, $th2);
        $context->rotate($comp->angle);
        $context->translate(-$tw2, -$th2);

        Pango::Cairo::update_context($context, $pcontext);
        Pango::Cairo::update_layout($context, $layout);

        my ($rw, $rh) = $self->_get_bounding_box($context, $layout);

        $tl->width($rw);
        $tl->height($rh);

        $context->restore;
    } else {

        Pango::Cairo::update_context($context, $pcontext);
        Pango::Cairo::update_layout($context, $layout);

        my ($ink, $log) = $layout->get_pixel_extents;

        $tl->width($log->{width});
        $tl->height($log->{height});
    }

    $tl->_layout($layout);

    return $tl;
}

sub _get_bounding_box {
    my ($self, $context, $layout) = @_;

    my ($lw, $lh) = Pango::Layout::get_size($layout);

    my $matrix = $context->get_matrix;
    my @corners = ([0,0], [$lw/1024,0], [$lw/1024,$lh/1024], [0,$lh/1024]);

    # Transform each of the four corners, the find the maximum X and Y
    # coordinates to create a bounding box

    my @points;
    foreach my $pt (@corners) {
        my ($x, $y) = $matrix->transform_point($pt->[0], $pt->[1]);
        push(@points, [ $x, $y ]);
    }

    my $maxX = $points[0]->[0];
    my $maxY = $points[0]->[1];
    my $minX = $points[0]->[0];
    my $minY = $points[0]->[1];

    foreach my $pt (@points) {

        if($pt->[0] > $maxX) {
            $maxX = $pt->[0];
        } elsif($pt->[0] < $minX) {
            $minX = $pt->[0];
        }

        if($pt->[1] > $maxY) {
            $maxY = $pt->[1];
        } elsif($pt->[1] < $minY) {
            $minY = $pt->[1];
        }
    }

    my $bw = $maxX - $minX;
    my $bh = $maxY - $minY;

    return ($bw, $bh);
}

no Moose;
1;
__END__

=head1 NAME

Graphics::Primitive::Driver::CairoPango - Cairo/Pango backend for Graphics::Primitive

=head1 SYNOPSIS

    use Graphics::Pritive::Component;
    use Graphics::Pritive::Component;
    use Graphics::Primitive::Driver::CairoPango;

    my $driver = Graphics::Primitive::Driver::CairoPango->new;
    my $container = Graphics::Primitive::Container->new(
        width => $form->sheet_width,
        height => $form->sheet_height
    );
    $container->border->width(1);
    $container->border->color($black);
    $container->padding(
        Graphics::Primitive::Insets->new(top => 5, bottom => 5, left => 5, right => 5)
    );
    my $comp = Graphics::Primitive::Component->new;
    $comp->background_color($black);
    $container->add_component($comp, 'c');

    my $lm = Layout::Manager::Compass->new;
    $lm->do_layout($container);

    my $driver = Graphics::Primitive::Driver::CairoPango->new(
        format => 'PDF'
    );
    $driver->draw($container);
    $driver->write('/Users/gphat/foo.pdf');

=head1 DESCRIPTION

This module draws Graphics::Primitive objects using Cairo and Pango.  This
is a separate distribution due to the Pango requirement.  The Pango specific
bits will be rolled into the normal Cairo driver at some point.

=head1 IMPLEMENTATION DETAILS

=over 4

=item B<Borders>

Borders are drawn clockwise starting with the top one.  Since cairo can't do
line-joins on different colored lines, each border overlaps those before it.
This is not the way I'd like it to work, but i'm opting to fix this later.
Consider yourself warned.

=back

=head1 METHODS

=head2 Constructor

=over 4

=item I<new>

Creates a new Graphics::Primitive::Driver::CairoPango object.  Requires a format.

  my $driver = Graphics::Primitive::Driver::CairoPango->new(format => 'PDF');

=back

=head2 Instance Methods

=over 4

=item I<antialias_mode>

Set/Get the antialias mode of this driver. Options are default, none, gray and
subpixel.

=item I<cairo>

This driver's Cairo::Context object

=item I<data>

Get the data in a scalar for this driver.

=item I<draw>

Draws the specified component.  Container's components are drawn recursively.

=item I<format>

Get the format for this driver.

=item I<get_textbox_layout ($font, $textbox)>

Returns this driver's implementation of a
L<TextLayout|Graphics::Primitive::Driver::TextLayout>.

=item I<reset>

Reset the driver.

=item I<surface>

Get/Set the surface on which this driver is operating.

=item I<write>

Write this driver's data to the specified file.

=back

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

Infinity Interactive, L<http://www.iinteractive.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geometry-primitive at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geometry-Primitive>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
