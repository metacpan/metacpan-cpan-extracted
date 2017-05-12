package Lego::From::PNG::Brick;

use strict;
use warnings;

BEGIN {
    $Lego::From::PNG::Brick::VERSION = '0.04';
}

use Lego::From::PNG::Const qw(:all);

use Data::Debug;

sub new {
    my $class = shift;
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my $hash = {};

    $hash->{$_} = $args{$_} for(qw(color depth length height meta));

    die "Invalid color" if ! scalar( grep { $_ eq $hash->{'color'} } LEGO_COLORS );

    # Default any undefined dimensions to 1
    $hash->{'depth'}  ||= 1;
    $hash->{'length'} ||= 1;
    $hash->{'height'} ||= 1;

    # Default meta to an empty hashref if it is undefined or an invalid ref
    $hash->{'meta'} = (! $hash->{'meta'} || ref($hash->{'meta'}) ne 'HASH') ? {} : $hash->{'meta'};

    my $self = bless ($hash, ref ($class) || $class);

    return $self;
}

sub id { &identifier }
sub identifier {
    my $self = shift;

    return $self->{'id'} ||= $self->color.'_'.join('x',$self->depth,$self->length,$self->height);
}

sub color  {
    my $self = shift;
    my $val  = shift;

    if(defined $val) {
        die "Invalid color" if ! scalar( grep { $_ eq $val } LEGO_COLORS );

        $self->{'color'} = $val;

        delete $self->{'id'};         # Clear out id
        delete $self->{'color_info'}; # Clear out color info on color change
    }

    return $self->{'color'};
}

sub depth {
    my $self = shift;
    my $val  = shift;

    if(defined $val) {
        $self->{'depth'} = $val * 1;

        delete $self->{'id'}; # Clear out id
    }

    return $self->{'depth'};
}

sub length {
    my $self = shift;
    my $val  = shift;

    if(defined $val) {
        $self->{'length'} = $val * 1;

        delete $self->{'id'}; # Clear out id
    }

    return $self->{'length'};
}

sub height {
    my $self = shift;
    my $val  = shift;

    if(defined $val) {
        $self->{'height'} = $val * 1;

        delete $self->{'id'}; # Clear out id
    }

    return $self->{'height'};
}

sub meta { shift->{'meta'} }

sub color_info {
    my $self = shift;

    return $self->{'color_info'} ||= do {
        my $color = $self->color;

        my ($on_key, $cn_key, $hex_key, $r_key, $g_key, $b_key) = (
            $color . '_OFFICIAL_NAME',
            $color . '_COMMON_NAME',
            $color . '_HEX_COLOR',
            $color . '_RGB_COLOR_RED',
            $color . '_RGB_COLOR_GREEN',
            $color . '_RGB_COLOR_BLUE',
        );

        no strict 'refs';

        +{
            'cid'           => $color,
            'official_name' => Lego::From::PNG::Const->$on_key,
            'common_name'   => Lego::From::PNG::Const->$cn_key,
            'hex_color'     => Lego::From::PNG::Const->$hex_key,
            'rgb_color'     => [
                Lego::From::PNG::Const->$r_key,
                Lego::From::PNG::Const->$g_key,
                Lego::From::PNG::Const->$b_key,
            ],
        };
    };
}

sub flatten {
    my $self = shift;

    $self->identifier; # Make sure it's generated

    my %hash;
    my @keys = qw(id color depth length height meta);

    @hash{ @keys } = @{ $self }{ @keys };

    return \%hash;
}

=pod

=head1 NAME

Lego::From::PNG::Brick - A simple representation of a lego brick

=head1 SYNOPSIS

  use Lego::From::PNG::Brick;

  my ($color, $depth, $length, $height) = ('BLACK', 1, 2, 1);

  # depth x length x height
  my $object = Lego::From::PNG::Brick->new(
      color  => $color,
      depth  => $depth,
      length => $length,
      height => $height,
      meta   => {} # Anything else we want to track
  );

  # Get at the data with accessors

=head1 DESCRIPTION

Representation of a Lego Brick plus additional meta data about that brick

=head1 USAGE

=head2 new

 Usage     : ->new()
 Purpose   : Returns Lego::From::PNG::Brick object

 Returns   : Lego::From::PNG::Brick object
 Argument  :
                color  -> must be a valid color from L<Lego::From::PNG::Const>
                depth  -> brick depth, defaults to 1
                length -> brick length, defaults to 1
                height -> brick height, defaults to 1
                meta   -> a hashref of additional meta data for the instanciated brick
 Throws    : Dies if the color is invalid

 Comment   : Clobbers meta if it's not a valid hashref
 See Also  :

=head2 id

See identifier

=head2 identifier

 Usage     : ->identifier()
 Purpose   : Returns brick id, which is based on color, depth, length and width

 Returns   : the indentifier. Format: <color>_<depth>x<length>x<height>
 Argument  :
 Throws    :

 Comment   : Identifiers aren't necessarily unique, more than one brick could have the same identifier and different meta for instance
 See Also  :


=head2 color

 Usage     : ->color() or ->color($new_color)
 Purpose   : Returns lego color for the brick, optionally a new color may be set

 Returns   : lego color value for this brick
 Argument  : Optional. Pass a scalar with a new valid color value to change the bricks color
 Throws    :

 Comment   :
 See Also  :

=head2 depth

 Usage     : ->depth() or ->depth($new_number)
 Purpose   : Returns depth for the brick, optionally a new depth may be set

 Returns   : depth value for this brick
 Argument  : Optional. Pass a scalar with a new valid depth value to change the bricks depth
 Throws    :

 Comment   :
 See Also  :

=head2 length

 Usage     : ->length() or ->length($new_number)
 Purpose   : Returns length for the brick, optionally a new length may be set

 Returns   : length value for this brick
 Argument  : Optional. Pass a scalar with a new valid length value to change the bricks length
 Throws    :

 Comment   :
 See Also  :

=head2 height

 Usage     : ->height() or ->height($new_number)
 Purpose   : Returns height for the brick, optionally a new height may be set

 Returns   : height value for this brick
 Argument  : Optional. Pass a scalar with a new valid height value to change the bricks height
 Throws    :

 Comment   :
 See Also  :

=head2 meta

 Usage     : ->meta()
 Purpose   : Returns brick meta data

 Returns   : brick meta data
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 color_info

 Usage     : ->color_info()
 Purpose   : Returns hash of color info related to bricks current color

 Returns   : hash of color info
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 flatten

 Usage     : ->flatten()
 Purpose   : Returns an unblessed version of the data

 Returns   : hashref of brick data
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head1 BUGS

=head1 SUPPORT

=head1 AUTHOR

    Travis Chase
    CPAN ID: GAUDEON
    gaudeon@cpan.org
    https://github.com/gaudeon/Lego-From-Png

=head1 COPYRIGHT

This program is free software licensed under the...

    The MIT License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

1;
