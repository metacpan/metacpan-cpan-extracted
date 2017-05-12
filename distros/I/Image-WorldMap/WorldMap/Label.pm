package Image::WorldMap::Label;
use strict;
use warnings;
use Image::Imlib2;
use Exporter;
use vars qw($XOFFSET $YOFFSET);

$XOFFSET = 0;
$YOFFSET = 0;

# Class method, creates a new label, given x, y and text
sub new {
    my ( $class, $x, $y, $text, $image, $dot_colour ) = @_;
    my $self = {};
    $self->{X}         = $x;
    $self->{Y}         = $y;
    $self->{LABELX}    = $x + $XOFFSET;
    $self->{LABELY}    = $y + $YOFFSET;
    $self->{TEXT}      = $text;
    $self->{DOTCOLOUR} = $dot_colour;

    bless $self, $class;

    my ( $w, $h ) = ( 0, 0 );
    ( $w, $h ) = $self->_boundingbox( $image, $text ) if defined $text;
    $self->{LABELW} = $w;
    $self->{LABELH} = $h;
    return $self;
}

sub x {
    my $self = shift;
    return $self->{X};
}

sub y {
    my $self = shift;
    return $self->{Y};
}

sub labelx {
    my $self = shift;
    return $self->{LABELX};
}

sub labely {
    my $self = shift;
    return $self->{LABELY};
}

sub text {
    my $self = shift;
    return $self->{TEXT};
}

sub labelwidth {
    my $self = shift;
    return $self->{LABELW};
}

sub labelheight {
    my $self = shift;
    return $self->{LABELH};
}

sub move {
    my ( $self, $x, $y ) = @_;
    $self->{LABELX} = $x;
    $self->{LABELY} = $y;
}

sub draw_label {
    my ( $self, $image ) = @_;
    my ( $x, $y, $labelx, $labely, $text ) = (
        $self->{X},      $self->{Y}, $self->{LABELX},
        $self->{LABELY}, $self->{TEXT}
    );

    if ( defined $text ) {

        # Draw the white outline
        $image->set_color( 255, 255, 255, 32 );
        $image->draw_text( $labelx + 1, $labely + 1, $text );
        $image->draw_text( $labelx - 1, $labely - 1, $text );
        $image->draw_text( $labelx + 1, $labely - 1, $text );
        $image->draw_text( $labelx - 1, $labely + 1, $text );
        $image->draw_text( $labelx + 1, $labely,     $text );
        $image->draw_text( $labelx - 1, $labely,     $text );
        $image->draw_text( $labelx,     $labely - 1, $text );
        $image->draw_text( $labelx,     $labely + 1, $text );

        # And finally draw the black text in the middle
        $image->set_color( 0, 0, 0, 255 );
        $image->draw_text( $labelx, $labely, $text );
    }
}

sub draw_dot {
    my ( $self, $image ) = @_;
    my ( $x, $y, $labelx, $labely, $text, $dot_colour ) = (
        $self->{X}, $self->{Y}, $self->{LABELX}, $self->{LABELY},
        $self->{TEXT}, $self->{DOTCOLOUR}
    );
    @$dot_colour = ( 255, 0, 0 ) if ( !defined $dot_colour );
    @$dot_colour = ( 255, 0, 0 ) if ( !defined $dot_colour );
    my @colour         = @$dot_colour;
    my @quarter_colour = map { int( $_ / 4 ); } @$dot_colour;
    my @half_colour    = map { int( $_ / 2 ); } @$dot_colour;

    my $radius = 1;

    if ( 0 && ( $labelx != $x or $labely != $y ) ) {

        # moved

        my ( $q, $w ) = ( $labelx, $labely );

        $image->set_color( 255, 255, 255, 32 );
        $image->draw_line( $x - 1, $y - 1, $q - 1, $w - 1 );
        $image->draw_line( $x + 1, $y + 1, $q + 1, $w + 1 );

        $image->set_colour( @quarter_colour, 255 );
        $image->draw_line( $x, $y, $q, $w );

        $image->set_colour( 0, 0, 0, 255 );
        $image->draw_point( $q - 1, $w - 1 );
        $image->draw_point( $q + 1, $w - 1 );
        $image->draw_point( $q - 1, $w + 1 );
        $image->draw_point( $q + 1, $w + 1 );
        $image->draw_point( $q - 1, $w );
        $image->draw_point( $q + 1, $w );
        $image->draw_point( $q,     $w - 1 );
        $image->draw_point( $q,     $w + 1 );

        $image->set_colour( 0, 0, 0, 128 );
        $image->draw_point( $q - 2, $w );
        $image->draw_point( $q + 2, $w );
        $image->draw_point( $q,     $w - 2 );
        $image->draw_point( $q,     $w + 2 );

        $image->set_colour( 0, 0, 0, 64 );
        $image->draw_point( $q - 2, $w + 1 );
        $image->draw_point( $q - 2, $w - 1 );
        $image->draw_point( $q + 2, $w - 1 );
        $image->draw_point( $q + 2, $w + 1 );
        $image->draw_point( $q - 1, $w - 2 );
        $image->draw_point( $q + 1, $w - 2 );
        $image->draw_point( $q - 1, $w + 2 );
        $image->draw_point( $q + 1, $w + 2 );

        $image->set_colour( 255, 255, 255, 255 );
        $image->draw_point( $q, $w );

        $image->set_colour( 255, 255, 255, 192 );
        $image->draw_point( $q - 1, $w );
        $image->draw_point( $q + 1, $w );
        $image->draw_point( $q,     $w - 1 );
        $image->draw_point( $q,     $w + 1 );

        $image->set_colour( 255, 255, 255, 128 );
        $image->draw_point( $q - 1, $w - 1 );
        $image->draw_point( $q + 1, $w - 1 );
        $image->draw_point( $q - 1, $w + 1 );
        $image->draw_point( $q + 1, $w + 1 );

    }

    $image->set_colour( 0, 0, 0, 255 );
    $image->draw_point( $x - 1, $y - 1 );
    $image->draw_point( $x + 1, $y - 1 );
    $image->draw_point( $x - 1, $y + 1 );
    $image->draw_point( $x + 1, $y + 1 );
    $image->draw_point( $x - 1, $y );
    $image->draw_point( $x + 1, $y );
    $image->draw_point( $x,     $y - 1 );
    $image->draw_point( $x,     $y + 1 );

    $image->set_colour( 0, 0, 0, 128 );
    $image->draw_point( $x - 2, $y );
    $image->draw_point( $x + 2, $y );
    $image->draw_point( $x,     $y - 2 );
    $image->draw_point( $x,     $y + 2 );

    $image->set_colour( 0, 0, 0, 64 );
    $image->draw_point( $x - 2, $y + 1 );
    $image->draw_point( $x - 2, $y - 1 );
    $image->draw_point( $x + 2, $y - 1 );
    $image->draw_point( $x + 2, $y + 1 );
    $image->draw_point( $x - 1, $y - 2 );
    $image->draw_point( $x + 1, $y - 2 );
    $image->draw_point( $x - 1, $y + 2 );
    $image->draw_point( $x + 1, $y + 2 );

    $image->set_colour( @$dot_colour, 255 );
    $image->draw_point( $x, $y );

    $image->set_colour( @$dot_colour, 192 );
    $image->draw_point( $x - 1, $y );
    $image->draw_point( $x + 1, $y );
    $image->draw_point( $x,     $y - 1 );
    $image->draw_point( $x,     $y + 1 );

    $image->set_colour( @$dot_colour, 128 );
    $image->draw_point( $x - 1, $y - 1 );
    $image->draw_point( $x + 1, $y - 1 );
    $image->draw_point( $x - 1, $y + 1 );
    $image->draw_point( $x + 1, $y + 1 );
}

# private method
sub _boundingbox($) {
    my ( $self, $image, $text ) = @_;

    return $image->get_text_size($text);
}

1;
