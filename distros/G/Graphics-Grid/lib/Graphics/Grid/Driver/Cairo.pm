package Graphics::Grid::Driver::Cairo;

# ABSTRACT: Cairo backend for Graphics::Grid

use Graphics::Grid::Class;

our $VERSION = '0.0001'; # VERSION

use Cairo;
use Scalar::Util qw(looks_like_number);
use List::AllUtils qw(min max pairwise);
use Math::Trig qw(:pi :radial deg2rad);
use Path::Tiny;
use Types::Standard qw(Enum Str InstanceOf Num);

use Graphics::Grid::Util qw(dots_to_cm cm_to_dots points_to_cm cm_to_points);

my $AntialiasMode = Enum [qw(default none gray subpixel)];
my $Format =
  ( Enum [qw(pdf ps png svg)] )->plus_coercions( Str, sub { lc($_) } );

my $matrix_points_to_cm =
  Cairo::Matrix->init_scale( points_to_cm(1), -points_to_cm(1) );


has 'antialias_mode' => ( is => 'rw', isa => $AntialiasMode );


has 'cairo' => (
    is      => 'rw',
    isa     => 'Cairo::Context',
    clearer => 'clear_cairo',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $ctx  = Cairo::Context->create( $self->surface );

        if ( defined( $self->antialias_mode ) ) {
            $ctx->set_antialias( $self->antialias_mode );
        }

        return $ctx;
    }
);


has format => ( is => 'ro', isa => $Format, default => 'png' );


has 'surface' => (
    is      => 'rw',
    clearer => 'clear_surface',
    lazy    => 1,
    default => sub {

        # Lazily create our surface based on the format they are required
        # to've chosen when creating this object
        my $self = shift;

        my $surface;

        my $width  = $self->width;
        my $height = $self->height;

        if ( $self->format eq 'png' ) {
            $surface = Cairo::ImageSurface->create( 'argb32', $width, $height );
        }
        elsif ( $self->format eq 'pdf' ) {
            croak('Your Cairo does not have PDF support!')
              unless Cairo::HAS_PDF_SURFACE;
            $surface = Cairo::PdfSurface->create_for_stream(
                sub { $self->{DATA} .= $_[1] }, $self, $width, $height

                  # $self->can('append_surface_data'), $self, $width, $height
            );
        }
        elsif ( $self->format eq 'ps' ) {
            croak('Your Cairo does not have PostScript support!')
              unless Cairo::HAS_PS_SURFACE;
            $surface = Cairo::PsSurface->create_for_stream(
                sub { $self->{DATA} .= $_[1] }, $self, $width, $height

                  # $self->can('append_surface_data'), $self, $width, $height
            );
        }
        elsif ( $self->format eq 'svg' ) {
            croak('Your Cairo does not have SVG support!')
              unless Cairo::HAS_SVG_SURFACE;
            $surface = Cairo::SvgSurface->create_for_stream(
                sub { $self->{DATA} .= $_[1] }, $self, $width, $height

                  # $self->can('append_surface_data'), $self, $width, $height
            );
        }
        else {
            croak( "Unknown format '" . $self->format . "'" );
        }

        return $surface;
    }
);

with qw(Graphics::Grid::Driver);

method _set_vptree( $vptree, $old_vptree = undef ) {
    my $ctx = $self->cairo;

    my $path = $self->current_vptree->path_from_root;

    # reset to basic setup
    $self->_reset_transform();

    # bypass root vp
    shift @$path;

    my $vp_width  = dots_to_cm( $self->width,  $self->dpi );
    my $vp_height = dots_to_cm( $self->height, $self->dpi );

    for my $vp (@$path) {
        my $x =
          $self->_transform_width_to_cm( $vp->x, 0, $vp->gp, $vp_width,
            $vp_height );
        my $y =
          $self->_transform_height_to_cm( $vp->y, 0, $vp->gp, $vp_width,
            $vp_height );
        my $width =
          $self->_transform_width_to_cm( $vp->width, 0, $vp->gp, $vp_width,
            $vp_height );
        my $height =
          $self->_transform_height_to_cm( $vp->height, 0, $vp->gp, $vp_width,
            $vp_height );

        $ctx->translate( $x, $y );

        if ( $vp->angle != 0 ) {
            $ctx->rotate( deg2rad( $vp->angle ) );
        }

        $ctx->translate( -$vp->hjust * $width, -$vp->vjust * $height );

        $vp_width  = $width;
        $vp_height = $height;
    }

    $self->_current_vp_width_cm($vp_width);
    $self->_current_vp_height_cm($vp_height);
}

method _reset_transform() {
    my $ctx = $self->cairo;

    # reset transfom
    my $identity_matrix = Cairo::Matrix->init_identity;
    $ctx->set_matrix($identity_matrix);

    #$ctx->set_font_matrix($identity_matrix);

    # set basic transform below

    # Cairo's Y direction is inverse from that of the grid library
    $ctx->translate( 0, $self->height );

    # We defaultly use cm as unit
    $self->_set_scale_cm();

}

method _set_scale_cm() {
    my $ctx = $self->cairo;
    $ctx->scale( $self->dpi / 2.54, -$self->dpi / 2.54 );
}
method _unset_scale_cm() {
    my $ctx = $self->cairo;
    $ctx->scale( 2.54 / $self->dpi, -2.54 / $self->dpi );
}


method data() {
    my $ctx = $self->cairo;

    if ( $self->format eq 'png' ) {
        my $buff;
        $self->surface->write_to_png_stream(
            sub {
                my ( $closure, $data ) = @_;
                $buff .= $data;
            }
        );
        return $buff;
    }

    $ctx->show_page;

    $ctx = undef;
    $self->clear_cairo;
    $self->clear_surface;

    return $self->{DATA};
}

method draw_circle($circle_grob) {
    my $ctx = $self->cairo;

    my $vp_width  = $self->_current_vp_width_cm;
    my $vp_height = $self->_current_vp_height_cm;

    my $gp = $self->current_gp;

    for my $idx ( 0 .. $circle_grob->elems - 1 ) {
        my $x =
          $self->_transform_width_to_cm( $circle_grob->x, $idx, $gp,
            $vp_width, $vp_height );
        my $y =
          $self->_transform_height_to_cm( $circle_grob->y, $idx, $gp,
            $vp_width, $vp_height );
        my $r = $self->_transform_width_to_cm( $circle_grob->r, $idx, $gp,
            min( $vp_width, $vp_height ) );

        $self->_draw_shape(
            $gp->at($idx),
            sub {
                my $c = shift;
                $c->new_path;
                $c->arc( $x, $y, $r, 0, pi2 );
            },
            true,
        );
    }
}

method draw_rect($rect_grob) {
    my $ctx = $self->cairo;

    my $vp_width  = $self->_current_vp_width_cm;
    my $vp_height = $self->_current_vp_height_cm;

    my $gp = $self->current_gp;

    for my $idx ( 0 .. $rect_grob->elems - 1 ) {
        my $x =
          $self->_transform_width_to_cm( $rect_grob->x, $idx, $gp, $vp_width,
            $vp_height );
        my $y =
          $self->_transform_height_to_cm( $rect_grob->y, $idx, $gp, $vp_width,
            $vp_height );
        my $width =
          $self->_transform_width_to_cm( $rect_grob->width, $idx, $gp,
            $vp_width, $vp_height );
        my $height =
          $self->_transform_height_to_cm( $rect_grob->height, $idx, $gp,
            $vp_width, $vp_height );

        my ( $left, $bottom ) =
          $rect_grob->calc_left_bottom( $x, $y, $width, $height );

        $self->_draw_shape(
            $gp->at($idx),
            sub {
                my $c = shift;
                $c->new_path;
                $c->rectangle( $left, $bottom, $width, $height );
            },
            true
        );
    }
}

my $path_func_lines = fun( $c, $points ) {
    $c->new_path;
    my $start_point = shift @$points;
    $c->move_to(@$start_point);
    for my $point (@$points) {
        $c->line_to(@$point);
    }
};

method draw_segments($segments_grob) {
    my $ctx = $self->cairo;

    my $gp = $self->current_gp;

    for my $idx ( 0 .. $segments_grob->elems - 1 ) {
        my ( $x0, $x1 ) =
          map {
            $self->_transform_width_to_cm( $segments_grob->$_, $idx, $gp );
          } qw(x0 x1);
        my ( $y0, $y1 ) =
          map {
            $self->_transform_height_to_cm( $segments_grob->$_, $idx, $gp );
          } qw(y0 y1);

        my @points_cm = ( [ $x0, $y0 ], [ $x1, $y1 ] );

        $self->_draw_shape(
            $gp->at($idx),
            fun($c)
            {
                $path_func_lines->( $c, \@points_cm );
            },
            false,
        );
    }
}

method draw_polyline($polyline_grob) {
    $self->_draw_polyline( $polyline_grob, $path_func_lines, false );
}

method draw_polygon($polygon_grob) {
    $self->_draw_polyline(
        $polygon_grob,
        fun( $c, $points )
        {
            $c->new_path;
            my $start_point = shift @$points;
            $c->move_to(@$start_point);
            for my $point (@$points) {
                $c->line_to(@$point);
            }
            $c->close_path;
        },
        true
    );
}

method _draw_polyline( $polyline_grob, $path_func, $is_fill = false ) {
    my $ctx = $self->cairo;

    my $gp = $self->current_gp;

    my $unique_ids = $polyline_grob->unique_ids;
    for my $idx ( 0 .. $#{$unique_ids} ) {
        my $id      = $unique_ids->[$idx];
        my $indexes = $polyline_grob->indexes_by_id($id);

        my @points_cm = map {
            my $x = $self->_transform_width_to_cm( $polyline_grob->x, $_, $gp );
            my $y =
              $self->_transform_height_to_cm( $polyline_grob->y, $_, $gp );
            [ $x, $y ];
        } @$indexes;

        $self->_draw_shape(
            $gp->at($idx),
            fun($c)
            {
                $path_func->( $c, \@points_cm );
            },
            $is_fill
        );
    }
}

method _draw_shape( $gp, $path_func, $is_fill = false ) {
    my $ctx = $self->cairo;

    # draw path
    $path_func->($ctx);

    # fill
    if ($is_fill) {
        $self->_set_fill($gp);
        $ctx->fill_preserve;
    }

    my $line_type = $gp->lty->[0];

    if ( $line_type ne 'blank' ) {

        my $line_width = max( $gp->lwd->[0] * $gp->lex->[0], 1 );
        my $line_end = $gp->lineend->[0];

        # grid's lineend/linejoin enums are same as Cairo's line_cap/line_join
        $ctx->set_line_cap($line_end);
        $ctx->set_line_join( $gp->linejoin->[0] );

        $ctx->set_miter_limit( $gp->linemitre->[0] );

        $self->_set_color($gp);

        $ctx->save;

        # $line_width is in absolute dots
        $self->_unset_scale_cm();

        $ctx->set_line_width($line_width);

        # dash is decided by the combination of lty, lwd, lineend
        unless ( $line_type eq 'solid' ) {
            my $adjust = $line_end eq 'butt' ? 0 : $line_width;

            state $dash_data = {
                dashed =>
                  [ 5 * $line_width - $adjust, 3 * $line_width + $adjust, ],
                dotted =>
                  [ 2 * $line_width - $adjust, 2 * $line_width + $adjust, ],
                dotdash => [
                    2 * $line_width - $adjust,
                    2 * $line_width + $adjust,
                    5 * $line_width - $adjust,
                    2 * $line_width + $adjust,
                ],
                longdash =>
                  [ 8 * $line_width - $adjust, 2 * $line_width + $adjust, ],
                twodash => [
                    3 * $line_width - $adjust,
                    1 * $line_width + $adjust,
                    7 * $line_width - $adjust,
                    1 * $line_width + $adjust,
                ],
            };

            if ( my $dashes = $dash_data->{$line_type} ) {
                $ctx->set_dash( 0, @$dashes );
            }
        }

        $ctx->stroke;

        $ctx->restore;

        return 1;
    }
    return 0;
}

method _set_color($gp) {
    my $ctx   = $self->cairo;
    my $color = $gp->col->[0];
    $color->alpha( $gp->alpha->[0] ) if $gp->has_alpha;
    $ctx->set_source_rgba( $color->as_array_with_alpha );
}

method _set_fill($gp) {
    my $ctx   = $self->cairo;
    my $color = $gp->fill->[0];
    $color->alpha( $gp->alpha->[0] ) if defined $gp->has_alpha;
    $ctx->set_source_rgba( $color->as_array_with_alpha );
}

method _select_font_face($gp) {
    my $ctx        = $self->cairo;
    my $fontfamily = $gp->fontfamily->[0];
    my $fontface   = $gp->fontface->[0];

    state $fontface_to_params = {
        plain       => [ 'normal',  'normal' ],
        bold        => [ 'normal',  'bold' ],
        italic      => [ 'italic',  'normal' ],
        oblique     => [ 'oblique', 'normal' ],
        bold_italic => [ 'italic',  'bold' ],
    };

    $ctx->select_font_face( $fontfamily,
        @{ $fontface_to_params->{$fontface} } );
}

method draw_text($text_grob) {
    my $ctx = $self->cairo;

    my $vp_width  = $self->_current_vp_width_cm;
    my $vp_height = $self->_current_vp_height_cm;

    my $gp = $self->current_gp;

    for my $idx ( 0 .. $text_grob->elems - 1 ) {
        my $text = $text_grob->label->[$idx];
        next unless ( length($text) );

        my $x =
          $self->_transform_width_to_cm( $text_grob->x, $idx, $gp,
            $vp_width, $vp_height );
        my $y =
          $self->_transform_height_to_cm( $text_grob->y, $idx, $gp,
            $vp_width, $vp_height );

        my $gp_single = $gp->at($idx);

        # Cairo does not support multiline text, so $gp->lineheight is not used

        my $font_size =
          max( $gp_single->fontsize->[0] * $gp_single->cex->[0], 1 );

        $ctx->set_font_size($font_size);
        my $font_matrix = $ctx->get_font_matrix->multiply($matrix_points_to_cm);
        $ctx->set_font_matrix($font_matrix);

        $self->_select_font_face($gp_single);
        my $exts = $ctx->text_extents($text);

        my $width  = $exts->{width};
        my $height = $exts->{height};

        my ( $left, $bottom ) =
          $text_grob->calc_left_bottom( $x, $y, $width, $height );

        $self->_set_color($gp_single);

        $ctx->save;

        my $angle_rad =
          deg2rad( $text_grob->rot->[ $idx % $text_grob->elems ] );
        if ($angle_rad) {
            $ctx->translate( $x, $y );
            $ctx->rotate($angle_rad);
            $ctx->translate( -$x, -$y );
        }
        $ctx->move_to( $left, $bottom );
        $ctx->show_text($text);

        $ctx->restore;
    }
}

use Graphics::Grid::Grob::Text;

# TODO: this is now just a poor man's implementation...
method draw_points($points_grob) {
    my $elems = $points_grob->elems;
    my $gp    = $self->current_gp;

    my $label_text;
    my $pch = $points_grob->pch;
    if ( looks_like_number($pch) ) {
        if ( $pch >= 32 ) {
            $label_text = chr($pch);
        }
    }
    else {
        $label_text = $pch;
    }

    if ($label_text) {

        my @font_size = map {
            cm_to_points(
                $self->_transform_width_to_cm( $points_grob->size, $_, $gp ) )
        } ( 0 .. $elems - 1 );
        my $new_gp =
          Graphics::Grid::GPar->new( fontsize => \@font_size )->merge($gp);

        my $text = Graphics::Grid::Grob::Text->new(
            label => [ ($label_text) x $points_grob->elems ],
            x     => $points_grob->x,
            y     => $points_grob->y,
            gp    => $new_gp,
        );

        $self->draw_text($text);
    }
    else {
        die "unsupported pch '$pch'";
    }
}


method write($file) {
    path($file)->spew_raw( $self->data );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Driver::Cairo - Cairo backend for Graphics::Grid

=head1 VERSION

version 0.0001

=head1 DESCRIPTION

This module draws Graphics::Grid objects using Cairo.
It is a subclass of L<Graphics::Grid::Driver>.

=head1 ATTRIBUTES

=head2 antialias_mode

The antialias mode of this driver.
Options are C<"default">, C<"none">, C<"gray"> and C<"subpixel">.

=head2 cairo

This driver's Cairo::Context object.

=head2 format

The format for this driver.

Allowed values are C<"png">, C<"svg">, C<"pdf">, C<"ps">. Default is C<"png">.

=head2 surface

The surface on which this driver is operating.

=head1 METHODS

=head2 data()

Get the data in a scalar for this driver.

=head2 write($file)

Write this driver's data to the specified file.

=head1 SEE ALSO

L<Graphics::Grid>

L<Graphics::Grid::Driver>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
