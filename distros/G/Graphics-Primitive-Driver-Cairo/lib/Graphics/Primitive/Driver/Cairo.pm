package Graphics::Primitive::Driver::Cairo;
$Graphics::Primitive::Driver::Cairo::VERSION = '0.47';
use Moose;
use Moose::Util::TypeConstraints;

# ABSTRACT: Cairo backend for Graphics::Primitive

use Cairo;
use Carp;
use Geometry::Primitive::Point;
use Geometry::Primitive::Rectangle;
use Graphics::Primitive::Driver::Cairo::TextLayout;
use IO::File;
use Math::Trig ':pi';

with 'Graphics::Primitive::Driver';

enum 'Graphics::Primitive::Driver::Cairo::AntialiasModes' => [
    qw(default none gray subpixel)
];

enum 'Graphics::Primitive::Driver::Cairo::Format' => [
    qw(PDF PS PNG SVG pdf ps png svg)
];


# If we encounter an operation with 'preserve' set to true we'll set this attr
# to the number of primitives in that path.  On each iteration we'll check
# this attribute.  If it's true, we'll skip that many primitives in the
# current path and then reset the value.  This allows us to leverage cairo's
# fill_preserve and stroke_perserve and avoid wasting time redrawing.
has '_preserve_count' => (
    isa => 'Str',
    is  => 'rw',
    default => sub { 0 }
);


has 'antialias_mode' => (
    is => 'rw',
    isa => 'Graphics::Primitive::Driver::Cairo::AntialiasModes'
);


has 'cairo' => (
    is => 'rw',
    isa => 'Cairo::Context',
    clearer => 'clear_cairo',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $ctx = Cairo::Context->create($self->surface);

        if(defined($self->antialias_mode)) {
            $ctx->set_antialias($self->antialias_mode);
        }

        return $ctx;
    }
);


has 'format' => (
    is => 'ro',
    isa => 'Graphics::Primitive::Driver::Cairo::Format',
    default => sub { 'PNG' }
);


has 'surface' => (
    is => 'rw',
    clearer => 'clear_surface',
    lazy => 1,
    default => sub {
        # Lazily create our surface based on the format they are required
        # to've chosen when creating this object
        my $self = shift;

        my $surface;

        my $width = $self->width;
        my $height = $self->height;

        if(uc($self->format) eq 'PNG') {
            $surface = Cairo::ImageSurface->create(
                'argb32', $width, $height
            );
        } elsif(uc($self->format) eq 'PDF') {
            croak('Your Cairo does not have PostScript support!')
                unless Cairo::HAS_PDF_SURFACE;
            $surface = Cairo::PdfSurface->create_for_stream(
                sub { $self->{DATA} .= $_[1] }, $self, $width, $height
                # $self->can('append_surface_data'), $self, $width, $height
            );
        } elsif(uc($self->format) eq 'PS') {
            croak('Your Cairo does not have PostScript support!')
                unless Cairo::HAS_PS_SURFACE;
            $surface = Cairo::PsSurface->create_for_stream(
                sub { $self->{DATA} .= $_[1] }, $self, $width, $height
                # $self->can('append_surface_data'), $self, $width, $height
            );
        } elsif(uc($self->format) eq 'SVG') {
            croak('Your Cairo does not have SVG support!')
                unless Cairo::HAS_SVG_SURFACE;
            $surface = Cairo::SvgSurface->create_for_stream(
                sub { $self->{DATA} .= $_[1] }, $self, $width, $height
                # $self->can('append_surface_data'), $self, $width, $height
            );
        } else {
            croak("Unknown format '".$self->format."'");
        }

        return $surface;
    }
);


sub data {
    my ($self) = @_;

    my $cr = $self->cairo;

    if(uc($self->format) eq 'PNG') {
        my $buff;
        $self->surface->write_to_png_stream(sub {
            my ($closure, $data) = @_;
            $buff .= $data;
        });
        return $buff;
    }

    $cr->show_page;

    $cr = undef;
    $self->clear_cairo;
    $self->clear_surface;

    return $self->{DATA};
}

around('draw', sub {
    my ($cont, $class, $comp) = @_;

    my $cairo = $class->cairo;

    $cairo->save;

    $cairo->translate($comp->origin->x, $comp->origin->y);
    $cairo->rectangle(0, 0, $comp->width, $comp->height);
    $cairo->clip;

    $cont->($class, $comp);

    $cairo->restore;
});


sub write {
    my ($self, $file) = @_;

    my $fh = IO::File->new($file, 'w')
        or die("Unable to open '$file' for writing: $!");
    $fh->binmode;
    $fh->print($self->data);
    $fh->close;
}

sub _draw_component {
    my ($self, $comp) = @_;

    my $width = $comp->width;
    my $height = $comp->height;

    my $context = $self->cairo;

    if(defined($comp->background_color)) {
        my ($mt, $mr, $mb, $ml) = $comp->margins->as_array;
        $context->set_source_rgba($comp->background_color->as_array_with_alpha);
        $context->rectangle(
            $mr, $mt, $comp->width - $mr - $ml, $comp->height - $mt - $mb
        );
        $context->fill;
    }

    if(defined($comp->border)) {

        my $border = $comp->border;

        if($border->homogeneous) {
            # Don't bother if there's no width
            if($border->top->width) {
                $self->_draw_simple_border($comp);
            }
        } else {
            $self->_draw_complex_border($comp);
        }
    }
}

sub _draw_complex_border {
    my ($self, $comp) = @_;

    my ($mt, $mr, $mb, $ml) = $comp->margins->as_array;

    my $context = $self->cairo;
    my $border = $comp->border;

    my $width = $comp->width;
    my $height = $comp->height;

    my $bt = $border->top;
    my $thalf = (defined($bt) && defined($bt->color))
        ? $bt->width / 2: 0;

    my $br = $border->right;
    my $rhalf = (defined($br) && defined($br->color))
        ? $br->width / 2: 0;

    my $bb = $border->bottom;
    my $bhalf = (defined($bb) && defined($bb->color))
        ? $bb->width / 2 : 0;

    my $bl = $border->left;
    my $lhalf = (defined($bl) && defined($bl->color))
        ? $bl->width / 2 : 0;

    if($thalf) {
        $context->move_to($ml, $mt + $thalf);
        $context->set_source_rgba($bt->color->as_array_with_alpha);

        $context->set_line_width($bt->width);
        $context->rel_line_to($width - $mr - $ml, 0);

        my $dash = $bt->dash_pattern;
        if(defined($dash) && scalar(@{ $dash })) {
            $context->set_dash(0, @{ $dash });
        }

        $context->stroke;

        $context->set_dash(0, []);
    }

    if($rhalf) {
        $context->move_to($width - $mr - $rhalf, $mt);
        $context->set_source_rgba($br->color->as_array_with_alpha);

        $context->set_line_width($br->width);
        $context->rel_line_to(0, $height - $mb);

        my $dash = $br->dash_pattern;
        if(defined($dash) && scalar(@{ $dash })) {
            $context->set_dash(0, @{ $dash });
        }

        $context->stroke;
        $context->set_dash(0, []);
    }

    if($bhalf) {
        $context->move_to($width - $mr, $height - $bhalf - $mb);
        $context->set_source_rgba($bb->color->as_array_with_alpha);

        $context->set_line_width($bb->width);
        $context->rel_line_to(-($width - $mr - $ml), 0);

        my $dash = $bb->dash_pattern;
        if(defined($dash) && scalar(@{ $dash })) {
            $context->set_dash(0, @{ $dash });
        }

        $context->stroke;
    }

    if($lhalf) {
        $context->move_to($ml + $lhalf, $mt);
        $context->set_source_rgba($bl->color->as_array_with_alpha);

        $context->set_line_width($bl->width);
        $context->rel_line_to(0, $height - $mb);

        my $dash = $bl->dash_pattern;
        if(defined($dash) && scalar(@{ $dash })) {
            $context->set_dash(0, @{ $dash });
        }

        $context->stroke;
        $context->set_dash(0, []);
    }
}

sub _draw_simple_border {
    my ($self, $comp) = @_;

    my $context = $self->cairo;

    my $border = $comp->border;
    my $top = $border->top;
    my $bswidth = $top->width;

    $context->set_source_rgba($top->color->as_array_with_alpha);

    my @margins = $comp->margins->as_array;

    $context->set_line_width($bswidth);
    $context->set_line_cap($top->line_cap);
    $context->set_line_join($top->line_join);

    $context->new_path;
    my $swhalf = $bswidth / 2;
    my $width = $comp->width;
    my $height = $comp->height;

    my $dash = $top->dash_pattern;
    if(defined($dash) && scalar(@{ $dash })) {
        $context->set_dash(0, @{ $dash });
    }

    $context->rectangle(
        $margins[3] + $swhalf, $margins[0] + $swhalf,
        $width - $bswidth - $margins[3] - $margins[1],
        $height - $bswidth - $margins[2] - $margins[0]
    );
    $context->stroke;

    # Reset dashing
    $context->set_dash(0, []);
}

sub _draw_textbox {
    my ($self, $comp) = @_;

    return unless defined($comp->text);

    $self->_draw_component($comp);

    my $bbox = $comp->inside_bounding_box;

    my $height = $bbox->height;
    my $height2 = $height / 2;
    my $width = $bbox->width;
    my $width2 = $width / 2;

    my $halign = $comp->horizontal_alignment;
    my $valign = $comp->vertical_alignment;

    my $context = $self->cairo;

    my $font = $comp->font;
    my $fsize = $font->size;
    $context->select_font_face(
        $font->face, $font->slant, $font->weight
    );
    $context->set_font_size($fsize);

    my $options = Cairo::FontOptions->create;
    $options->set_antialias($font->antialias_mode);
    $options->set_subpixel_order($font->subpixel_order);
    $options->set_hint_style($font->hint_style);
    $options->set_hint_metrics($font->hint_metrics);
    $context->set_font_options($options);

    my $angle = $comp->angle;

    $context->set_source_rgba($comp->color->as_array_with_alpha);

    my $lh = $comp->line_height;
    $lh = $fsize unless(defined($lh));

    my $yaccum = $bbox->origin->y;

    foreach my $line (@{ $comp->layout->lines }) {
        my $text = $line->{text};
        my $tbox = $line->{box};

        my $o = $tbox->origin;
        my $bbo = $bbox->origin;
        my $twidth = $tbox->width;
        my $theight = $tbox->height;

        my $x = $bbox->origin->x + $o->x;

        my $ydiff = $theight + $o->y;
        my $xdiff = $twidth + $o->x;

        my $realh = $theight + $ydiff;
        my $realw = $twidth + $xdiff;
        my $theight2 = $realh / 2;
        my $twidth2 = $twidth / 2;

        my $y = $yaccum + $theight;

        $context->save;

        if($angle) {
            my $twidth2 = $twidth / 2;
            my $cwidth2 = $width / 2;
            my $cheight2 = $height / 2;

            $context->translate($cwidth2, $cheight2);
            $context->rotate($angle);
            $context->translate(-$cwidth2, -$cheight2);

            $context->move_to($cwidth2 - $twidth2, $cheight2 + $theight / 3.5);
            $context->show_text($text);

        } else {
            if($halign eq 'right') {
                $x += $width - $twidth;
            } elsif($halign eq 'center') {
                $x += $width2 - $twidth2;
            }

            if($valign eq 'bottom') {
                $y = $height - $ydiff;
            } elsif($valign eq 'center') {
                $y += $height2 - $theight2;
            } else {
                $y -= $ydiff;
            }

            $context->move_to($x, $y);
            $context->show_text($text);
        }

        $context->restore;
        $yaccum += $lh;
    }

}

sub _draw_arc {
    my ($self, $arc) = @_;

    my $context = $self->cairo;
    my $o = $arc->origin;
    if($arc->angle_start > $arc->angle_end) {
        $context->arc_negative(
            $o->x, $o->y, $arc->radius, $arc->angle_start, $arc->angle_end
        );
    } else {
        $context->arc(
            $o->x, $o->y, $arc->radius, $arc->angle_start, $arc->angle_end
        );
    }
}

sub _draw_bezier {
    my ($self, $bezier) = @_;

    my $context = $self->cairo;
    my $start = $bezier->start;
    my $end = $bezier->end;
    my $c1 = $bezier->control1;
    my $c2 = $bezier->control2;

    $context->curve_to($c1->x, $c1->y, $c2->x, $c2->y, $end->x, $end->y);
}

sub _draw_canvas {
    my ($self, $comp) = @_;

    $self->_draw_component($comp);

    foreach (@{ $comp->paths }) {

        $self->_draw_path($_->{path}, $_->{op});
    }
}

sub _draw_circle {
    my ($self, $circle) = @_;

    my $context = $self->cairo;
    my $o = $circle->origin;
    $context->new_sub_path;
    $context->arc(
        $o->x, $o->y, $circle->radius, 0, pi2
    );
}

sub _draw_ellipse {
    my ($self, $ell) = @_;

    my $cairo = $self->cairo;
    my $o = $ell->origin;

    $cairo->new_sub_path;
    $cairo->save;
    $cairo->translate($o->x, $o->y);
    $cairo->scale($ell->width / 2, $ell->height / 2);
    $cairo->arc(
        $o->x, $o->y, 1, 0, pi2
    );
    $cairo->restore;
}

sub _draw_image {
    my ($self, $comp) = @_;

    $self->_draw_component($comp);

    my $cairo = $self->cairo;

    $cairo->save;

    my $imgs = Cairo::ImageSurface->create_from_png($comp->image);

    my $bb = $comp->inside_bounding_box;

    my $bumpx = 0;
    my $bumpy = 0;
    if($comp->horizontal_alignment eq 'center') {
        $bumpx = $bb->width / 2;
        if(defined($comp->scale)) {
            $bumpx -= $comp->scale->[0] * ($imgs->get_width / 2);
        } else {
            $bumpx -= $imgs->get_width / 2;
        }
    } elsif($comp->horizontal_alignment eq 'right') {
        $bumpx = $bb->width;
        if(defined($comp->scale)) {
            $bumpx -= $comp->scale->[0] * $imgs->get_width;
        } else {
            $bumpx -= $imgs->get_width;
        }
    }

    if($comp->vertical_alignment eq 'center') {
        $bumpy = $bb->height / 2;
        if(defined($comp->scale)) {
            $bumpy -= $comp->scale->[1] * ($imgs->get_height / 2);
        } else {
            $bumpy -= $imgs->get_height / 2;
        }
    } elsif($comp->vertical_alignment eq 'bottom') {
        $bumpy = $bb->height;
        if(defined($comp->scale)) {
            $bumpy -= $comp->scale->[1] * $imgs->get_height;
        } else {
            $bumpy -= $imgs->get_height;
        }
    }

    $cairo->translate($bb->origin->x + $bumpx, $bb->origin->y + $bumpy);
    $cairo->rectangle(0, 0, $imgs->get_width, $imgs->get_height);
    $cairo->clip;

    if(defined($comp->scale)) {
        $cairo->scale($comp->scale->[0], $comp->scale->[1]);
    }

    $cairo->rectangle(
       0, 0, $imgs->get_width, $imgs->get_height
    );

    $cairo->set_source_surface($imgs, 0, 0);

    $cairo->fill;

    $cairo->restore;
}

sub _draw_path {
    my ($self, $path, $op) = @_;

    my $context = $self->cairo;

    # If preserve count is set we've "preserved" a path that's made up 
    # of X primitives.  Set the sentinel to the the count so we skip that
    # many primitives
    my $pc = $self->_preserve_count;
    if($pc) {
        $self->_preserve_count(0);
    } else {
        $context->new_path;
    }

    my $pcount = $path->primitive_count;
    for(my $i = $pc; $i < $pcount; $i++) {
        my $prim = $path->get_primitive($i);
        my $hints = $path->get_hint($i);

        if(defined($hints)) {
            unless($hints->{contiguous}) {
                my $ps = $prim->point_start;
                $context->move_to(
                    $ps->x, $ps->y
                );
            }
        }

        # FIXME Check::ISA
        if($prim->isa('Geometry::Primitive::Line')) {
            $self->_draw_line($prim);
        } elsif($prim->isa('Geometry::Primitive::Rectangle')) {
            $self->_draw_rectangle($prim);
        } elsif($prim->isa('Geometry::Primitive::Arc')) {
            $self->_draw_arc($prim);
        } elsif($prim->isa('Geometry::Primitive::Bezier')) {
            $self->_draw_bezier($prim);
        } elsif($prim->isa('Geometry::Primitive::Circle')) {
            $self->_draw_circle($prim);
        } elsif($prim->isa('Geometry::Primitive::Ellipse')) {
            $self->_draw_ellipse($prim);
        } elsif($prim->isa('Geometry::Primitive::Polygon')) {
            $self->_draw_polygon($prim);
        }
    }

    if($op->isa('Graphics::Primitive::Operation::Stroke')) {
        $self->_do_stroke($op);
    } elsif($op->isa('Graphics::Primitive::Operation::Fill')) {
        $self->_do_fill($op);
    }

    if($op->preserve) {
        $self->_preserve_count($path->primitive_count);
    }
}

sub _draw_line {
    my ($self, $line) = @_;

    my $context = $self->cairo;
    my $end = $line->end;
    $context->line_to($end->x, $end->y);
}

sub _draw_polygon {
    my ($self, $poly) = @_;

    my $context = $self->cairo;
    for(my $i = 1; $i < $poly->point_count; $i++) {
        my $p = $poly->get_point($i);
        $context->line_to($p->x, $p->y);
    }
    $context->close_path;
}

sub _draw_rectangle {
    my ($self, $rect) = @_;

    my $context = $self->cairo;
    $context->rectangle(
        $rect->origin->x, $rect->origin->y,
        $rect->width, $rect->height
    );
}

sub _do_fill {
    my ($self, $fill) = @_;

    my $context = $self->cairo;
    my $paint = $fill->paint;

    # FIXME Check::ISA?
    if($paint->isa('Graphics::Primitive::Paint::Gradient')) {

        my $patt;
        if($paint->isa('Graphics::Primitive::Paint::Gradient::Linear')) {
            $patt = Cairo::LinearGradient->create(
                $paint->line->start->x, $paint->line->start->y,
                $paint->line->end->x, $paint->line->end->y,
            );
        } elsif($paint->isa('Graphics::Primitive::Paint::Gradient::Radial')) {
            $patt = Cairo::RadialGradient->create(
                $paint->start->origin->x, $paint->start->origin->y,
                $paint->start->radius,
                $paint->end->origin->x, $paint->end->origin->y,
                $paint->end->radius
            );
        } else {
            croak('Unknown gradient type: '.ref($paint));
        }

        foreach my $stop ($paint->stops) {
            my $color = $paint->get_stop($stop);
            $patt->add_color_stop_rgba(
                $stop, $color->red, $color->green,
                $color->blue, $color->alpha
            );
        }
        $context->set_source($patt);

    } elsif($paint->isa('Graphics::Primitive::Paint::Solid')) {
        $context->set_source_rgba($paint->color->as_array_with_alpha);
    }

    if($fill->preserve) {
        $context->fill_preserve;
    } else {
        $context->fill;
    }
}

sub _do_stroke {
    my ($self, $stroke) = @_;

    my $br = $stroke->brush;

    my $context = $self->cairo;
    $context->set_source_rgba($br->color->as_array_with_alpha);
    $context->set_line_cap($br->line_cap);
    $context->set_line_join($br->line_join);
    $context->set_line_width($br->width);

    my $dash = $br->dash_pattern;
    if(defined($dash) && scalar(@{ $dash })) {
        $context->set_dash(0, @{ $dash });
    }

    if($stroke->preserve) {
        $context->stroke_preserve;
    } else {
        $context->stroke;
    }

    # Reset dashing
    $context->set_dash(0, []);
}

sub _finish_page {
    my ($self) = @_;

    my $context = $self->cairo;
    $context->show_page;
}

sub _resize {
    my ($self, $width, $height) = @_;

    # Don't resize unless we have to
    if(($self->width != $width) || ($self->height != $height)) {
        $self->surface->set_size($width, $height);
    }
}


sub get_text_bounding_box {
    my ($self, $tb, $text) = @_;

    my $context = $self->cairo;

    my $font = $tb->font;

    unless(defined($text)) {
        $text = $tb->text;
    }

    $context->new_path;

    my $fsize = $font->size;

    my $options = Cairo::FontOptions->create;
    $options->set_antialias($font->antialias_mode);
    $options->set_subpixel_order($font->subpixel_order);
    $options->set_hint_style($font->hint_style);
    $options->set_hint_metrics($font->hint_metrics);
    $context->set_font_options($options);

    # my $key = "$text||".$font->face.'||'.$font->slant.'||'.$font->weight.'||'.$fsize;

    # If our text + font key is found, return the box we already made.
    # if(exists($self->{TBCACHE}->{$key})) {
    #     return ($self->{TBCACHE}->{$key}->[0], $self->{TBCACHE}->{$key}->[1]);
    # }

    # my @exts;
    my $exts;
    if($text eq '') {
        # Catch empty lines.  There's no sense trying to get it's height.  We
        # just set it to the height of the font and move on.
        # @exts = (0, -$font->size, 0, 0);
        $exts->{y_bearing} = 0;
        $exts->{x_bearing} = 0;
        $exts->{x_advance} = 0;
        $exts->{width} = 0;
        $exts->{height} = $fsize;
    } else {
        $context->select_font_face(
            $font->face, $font->slant, $font->weight
        );
        $context->set_font_size($fsize);
        $exts = $context->text_extents($text);
    }

    my $tbr = Geometry::Primitive::Rectangle->new(
        origin  => Geometry::Primitive::Point->new(
            x => $exts->{x_bearing},#$exts[0],
            y => $exts->{y_bearing},#$exts[1],
        ),
        width   => $exts->{width} + $exts->{x_bearing} + 1,#abs($exts[2]) + abs($exts[0]),
        height  => $exts->{height},#$tbsize
    );

    my $cb = $tbr;
    if($tb->angle) {

        $context->save;

        my $tw2 = $tb->width / 2;
        my $th2 = $tb->height / 2;

        $context->translate($tw2, $th2);
        $context->rotate($tb->angle);
        $context->translate(-$tw2, -$th2);

        my ($rw, $rh) = $self->_get_bounding_box($context, $exts);

        $cb = Geometry::Primitive::Rectangle->new(
            origin  => $tbr->origin,
            width   => $rw,
            height  => $rh
        );

        $context->restore;
    }

    # $self->{TBCACHE}->{$key} = [ $cb, $tbr ];

    return ($cb, $tbr);
}


sub get_textbox_layout {
    my ($self, $comp) = @_;

    my $tl = Graphics::Primitive::Driver::Cairo::TextLayout->new(
        component => $comp
    );
    $tl->layout($self);
    return $tl;
}


sub reset {
    my ($self) = @_;

    $self->clear_cairo;
}

sub _get_bounding_box {
    my ($self, $context, $exts) = @_;

    my $lw = $exts->{width} + abs($exts->{x_bearing});
    my $lh = $exts->{height} + abs($exts->{y_bearing});

    my $matrix = $context->get_matrix;
    my @corners = ([0,0], [$lw,0], [$lw,$lh], [0,$lh]);

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

=pod

=head1 NAME

Graphics::Primitive::Driver::Cairo - Cairo backend for Graphics::Primitive

=head1 VERSION

version 0.47

=head1 SYNOPSIS

    use Graphics::Primitive::Component;
    use Graphics::Primitive::Driver::Cairo;

    my $driver = Graphics::Primitive::Driver::Cairo->new;
    my $container = Graphics::Primitive::Container->new(
        width => 800,
        height => 600
    );
    my $black = Graphics::Primitive::Color->new(red => 0, green => 0, blue => 0);
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

    my $driver = Graphics::Primitive::Driver::Cairo->new(
        format => 'PDF'
    );
    $driver->draw($container);
    $driver->write('/Users/gphat/foo.pdf');

=head1 DESCRIPTION

This module draws Graphics::Primitive objects using Cairo.

=head1 IMPLEMENTATION DETAILS

=over 4

=item B<Borders>

Borders are drawn clockwise starting with the top one.  Since cairo can't do
line-joins on different colored lines, each border overlaps those before it.
This is not the way I'd like it to work, but i'm opting to fix this later.
Consider yourself warned.

=back

=head1 ATTRIBUTES

=head2 antialias_mode

Set/Get the antialias mode of this driver. Options are default, none, gray and
subpixel.

=head2 cairo

This driver's Cairo::Context object

=head2 format

Get the format for this driver.

=head2 surface

Get/Set the surface on which this driver is operating.

=head1 METHODS

=head2 data

Get the data in a scalar for this driver.

=head2 write ($file)

Write this driver's data to the specified file.

=head2 get_text_bounding_box ($font, $text, $angle)

Returns two L<Rectangles|Graphics::Primitive::Rectangle> that encloses the
supplied text. The origin's x and y maybe negative, meaning that the glyphs in
the text extending left of x or above y.

The first rectangle is the bounding box required for a container that wants to
contain the text.  The second box is only useful if an optional angle is
provided.  This second rectangle is the bounding box of the un-rotated text
that allows for a controlled rotation.  If no angle is supplied then the
two rectangles are actually the same object.

If the optional angle is supplied the text will be rotated by the supplied
amount in radians.

=head2 get_textbox_layout ($tb)

Returns a L<Graphics::Primitive::Driver::TextLayout> for the supplied
textbox.

=head2 reset

Reset the driver.

=head2 draw

Draws the specified component.  Container's components are drawn recursively.

=head1 ACKNOWLEDGEMENTS

Danny Luna

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
