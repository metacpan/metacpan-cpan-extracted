package Lorem::Role::Style::HasBorders;
{
  $Lorem::Role::Style::HasBorders::VERSION = '0.22';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

use Lorem::Style::Util qw( parse_border );

has [qw(border_bottom_color border_left_color border_right_color border_top_color)] => (
    is => 'rw',
    isa => 'Str',
    default => '#000000',
);

has [qw(border_bottom_style border_left_style border_right_style border_top_style)] => (
    is => 'rw',
    isa => 'Str',
    default => 'none',
);

has [qw(border_bottom_width border_left_width border_right_width border_top_width)] => (
    is => 'rw',
    isa => 'Str',
    default => 'thin',
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    
    my %args = @_;
    my %new_args;

    # border
    if ( exists $args{border} ) {
        my $parsed = parse_border $args{border};
        for my $a (qw/width style color/) {
            next if ! defined $parsed->{$a};
            if ( defined $parsed->{$a} ) {
                for my $s (qw/bottom left right top/) {
                    $new_args{ 'border_' . $s . '_' . $a } = $parsed->{$a};
                }
            }
        }
        delete $args{border};
    }
    # border-left border-right border-top border-bottom
    for my $s ( qw/bottom left right top/ ) {
        my $att = 'border_' . $s;
        if ( exists $args{$att} ) {
            my $parsed = parse_border $args{$att};
            for my $a ( qw/width style color/ ) {
                next if ! defined $parsed->{$a};
                if ( defined $parsed->{$a} ) {
                    $new_args{ 'border_' . $s . '_' . $a } = $parsed->{$a};
                }
            }
            delete $args{$att};
        }
    }
    # border-color border-style border-width
    for my $a (qw/color style width/) {
        my $att = 'border_' . $a;
        if ( exists $args{$att} ) {
            for my $s ( qw/bottom left right top/ ) {
                $new_args{ 'border_' . $s . '_' . $a } = $args{$att};
            }
            delete $args{$att};
        }
    }
    
    my %return = (%args, %new_args);
    return $class->$orig(%return);
};

sub set_border {
    my ( $self, $input ) = @_;
    my $parsed = parse_border $input;
    
    if ( defined $parsed->{width} ) {
        $self->set_border_bottom_width( $parsed->{width} );
        $self->set_border_left_width( $parsed->{width} );
        $self->set_border_right_width( $parsed->{width} );
        $self->set_border_top_width( $parsed->{width} );
    }
    if ( defined $parsed->{style} ) {
        $self->set_border_bottom_style( $parsed->{style} );
        $self->set_border_left_style( $parsed->{style} );
        $self->set_border_right_style( $parsed->{style} );
        $self->set_border_top_style( $parsed->{style} );
    }
    if ( defined $parsed->{color} ) {
        $self->set_border_bottom_color( defined $parsed->{color} );
        $self->set_border_left_color( defined $parsed->{color} );
        $self->set_border_right_color( defined $parsed->{color} );
        $self->set_border_top_color( defined $parsed->{color} );
    }    
}

sub set_border_bottom  {
    my ( $self, $input ) = @_;
    my ($width, $border_style, $color) = $self->_parse_border_input( $input );
    defined $width && $self->set_border_bottom_width( $width );
    defined $border_style && $self->set_border_bottom_style( $border_style );
    defined $color &&  $self->set_border_bottom_color( $color );   
}


sub set_border_left  {
    my ( $self, $input ) = @_;
    my ($width, $border_style, $color) = $self->_parse_border_input( $input );
    defined $width && $self->set_border_left_width( $width );
    defined $border_style && $self->set_border_left_style( $border_style );
    defined $color &&  $self->set_border_left_color( $color );   
}

sub set_border_right  {
    my ( $self, $input ) = @_;
    my ($width, $border_style, $color) = $self->_parse_border_input( $input );
    defined $width && $self->set_border_right_width( $width );
    defined $border_style && $self->set_border_right_style( $border_style );
    defined $color &&  $self->set_border_right_color( $color ); 
}

sub set_border_top  {
    my ( $self, $input ) = @_;
    my ($width, $border_style, $color) = $self->_parse_border_input( $input );
    defined $width && $self->set_border_top_width( $width );
    defined $border_style && $self->set_border_top_style( $border_style );
    defined $color &&  $self->set_border_top_color( $color ); 
}

sub set_border_color  {
    my ( $self, $input ) = @_;
    $self->set_border_bottom_color( $input );
    $self->set_border_left_color( $input );
    $self->set_border_right_color( $input );
    $self->set_border_top_color( $input );
}

sub set_border_style  {
    my ( $self, $input ) = @_;
    $self->set_border_bottom_style( $input );
    $self->set_border_left_style( $input );
    $self->set_border_right_style( $input );
    $self->set_border_top_style( $input );
}

sub set_border_width  {
    my ( $self, $input ) = @_;
    $self->set_border_bottom_width( $input );
    $self->set_border_left_width( $input );
    $self->set_border_right_width( $input );
    $self->set_border_top_width( $input );
}











1;
