package HTML::FormFu::Validator::Imager::Size;
{
  $HTML::FormFu::Validator::Imager::Size::VERSION = '1.00';
}
use Moose;
use MooseX::Attribute::Chained;

extends 'HTML::FormFu::Validator';

use Scalar::Util qw/ blessed /;
use Carp qw/ croak /;

has exact_width  => ( is => 'rw', traits => ['Chained'] );
has exact_height => ( is => 'rw', traits => ['Chained'] );
has width        => ( is => 'rw', traits => ['Chained'] );
has height       => ( is => 'rw', traits => ['Chained'] );
has pixels       => ( is => 'rw', traits => ['Chained'] );

sub validate_value {
    my ( $self, $value ) = @_;
    
    return 1 if !defined $value || $value eq "";

    croak "not an Imager object"
        unless blessed($value) && $value->isa('Imager');
    
    my $width  = $value->getwidth;
    my $height = $value->getheight;
    
    # exact width
    
    if ( my $max = $self->exact_width ) {
        return if $width != $max;
    }
    
    # exact height
    
    if ( my $max = $self->exact_height ) {
        return if $height != $max;
    }
    
    # max dimension
    
    if ( my $max = $self->pixels ) {
        return if $width > $max || $height > $max;
    }
    
    # max width
    
    if ( my $max = $self->width ) {
        return if $width > $max;
    }
    
    # max height
    
    if ( my $max = $self->height ) {
        return if $height > $max;
    }
    
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTML::FormFu::Validator::Imager::Size

=head1 SYNOPSIS

    ---
    elements:
      - type: file
        name: photo
        inflators:
          - type: Imager
        validators:
          - type: 'Imager::Size'
            pixels: 200

=head1 METHODS

=head2 pixels

The maximum allowed pixel dimension of either the width or height.

=head2 width

The maximum allowed width in pixels.

=head2 height

The maximum allowed height in pixels.

=head2 exact_width

If set, the image width in pixels must exactly match this value.

=head2 exact_height

If set, the image height in pixels must exactly match this value.

=head1 SEE ALSO

L<HTML::FormFu::Imager>, L<HTML::FormFu>

=head1 AUTHOR

Carl Franks

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
