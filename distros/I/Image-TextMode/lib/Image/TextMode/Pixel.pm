package Image::TextMode::Pixel;

use Moo;
use Types::Standard qw( Int );

# Attribute byte constants
my $ATTR_BG_NB = 240;
my $ATTR_BLINK = 128;
my $ATTR_BG    = 112;
my $ATTR_FG    = 15;

has 'char' => ( is => 'rw', isa => sub { die '$_[ 0 ] is not a single character' unless length( $_[ 0 ] ) == 1 } );

has 'fg' => (
    is      => 'rw',
    isa     => Int,
    default => 0,
);

has 'bg' => (
    is      => 'rw',
    isa     => Int,
    default => 0,
);

has 'blink' => (
    is      => 'rw',
    isa     => Int,
    default => 0,
);

=head1 NAME

Image::TextMode::Pixel - A base class to represent a text mode "pixel"

=head1 DESCRIPTION

Represents a "pixel; i.e. a character plus, foreground and background colors and
an blink mode setting.

=head1 ACCESSORS

=over 4

=item * char - The character for the pixel

=item * fg - The foreground palette index

=item * bg - The background palette index

=item * blink - The blink bit

=back

=head1 METHODS

=head2 new( %args )

Creates a new pixel. If you supply an C<attr> argument, then it will be
broken down into its components (fg, bg, and blink). By default, blink mode
is off (aka iCEColor is on). Pass a true value for C<blink_mode> to enabled
it.

=head2 BUILDARGS( %args )

A Moose override to extract the C<attr> key and convert it to components,
should it exist.

=cut

sub BUILDARGS {
    my ( $class, @rest ) = @_;

    my $options = {};
    if ( @rest % 2 != 0 ) {
        $options = pop @rest;
    }

    my %args = @rest;
    my $attr = delete $args{ attr };

    if ( $attr ) {
        $attr = $class->_attr_to_components( $attr, $options );
        %args = ( %args, %$attr );
    }

    return \%args;
}

sub _attr_to_components {
    my ( $self, $attr, $options ) = @_;
    $options ||= {};
    my $blink = $options->{ blink_mode };
    my %data;

    $data{ fg }    = $attr & $ATTR_FG;
    $data{ bg }    = ( $attr & ( $blink ? $ATTR_BG : $ATTR_BG_NB ) ) >> 4;
    $data{ blink } = ( $attr && $ATTR_BLINK ) >> 7 if $blink;

    return \%data;
}

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2015 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
