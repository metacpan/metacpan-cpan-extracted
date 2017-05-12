package # Hide from CPAN
    MockDriver;
use Moose;

with 'Graphics::Primitive::Driver';

use MockLayout;

use Geometry::Primitive::Rectangle;

has 'height' => ( is => 'rw', isa => 'Num' );
has 'width' => ( is => 'rw', isa => 'Num' );

sub get_textbox_layout {
    my ($self, $tb) = @_;

    return MockLayout->new(
        width => $tb->width,
        component => $tb
    );
}

sub get_text_bounding_box {
    my ($self, $font, $text) = @_;

    my $height = int(rand(3) + 2);

    return (
        Geometry::Primitive::Rectangle->new(
            origin => [0, 0],
            width => length($text),
            height => 4#$height
        ),
        Geometry::Primitive::Rectangle->new(
            origin => [0, 0],
            width => length($text),
            height => 4#$height
        ),
    );
}

sub _do_fill { }

sub _do_stroke { }

sub _draw_arc { }

sub _draw_bezier { }

sub _draw_canvas { }

sub _draw_circle { }

sub _draw_component { }

sub _draw_ellipse { }

sub _draw_line { }

sub _draw_path { }

sub _draw_polygon { }

sub _draw_rectangle { }

sub _draw_textbox { }

sub _finish_page { }

sub _resize { }

sub data { }

sub reset { }

sub write { }

1;