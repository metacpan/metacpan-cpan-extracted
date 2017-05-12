package FuseBead::From::PNG::Bead;

use strict;
use warnings;

BEGIN {
    $FuseBead::From::PNG::Bead::VERSION = '0.02';
}

use FuseBead::From::PNG::Const qw(:all);

use Data::Debug;

sub new {
    my $class = shift;
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my $hash = {};

    $hash->{$_} = $args{$_} for(qw(color meta));

    die "Invalid color" if ! scalar( grep { $_ eq $hash->{'color'} } BEAD_COLORS );

    # Default dimensions
    $hash->{'diameter'} = BEAD_DIAMETER;

    # Default meta to an empty hashref if it is undefined or an invalid ref
    $hash->{'meta'} = (! $hash->{'meta'} || ref($hash->{'meta'}) ne 'HASH') ? {} : $hash->{'meta'};

    my $self = bless ($hash, ref ($class) || $class);

    return $self;
}

sub id { &identifier }
sub identifier {
    my $self = shift;

    return $self->{'id'} ||= $self->color;
}

sub color  {
    my $self = shift;
    my $val  = shift;

    if(defined $val) {
        die "Invalid color" if ! scalar( grep { $_ eq $val } BEAD_COLORS );

        $self->{'color'} = $val;

        delete $self->{'id'};         # Clear out id
        delete $self->{'color_info'}; # Clear out color info on color change
    }

    return $self->{'color'};
}

sub diameter { shift->{'diameter'} }

sub meta { shift->{'meta'} }

sub color_info {
    my $self = shift;

    return $self->{'color_info'} ||= do {
        my $color = $self->color;

        my ($n_key, $hex_key, $r_key, $g_key, $b_key) = (
            $color . '_NAME',
            $color . '_HEX_COLOR',
            $color . '_RGB_COLOR_RED',
            $color . '_RGB_COLOR_GREEN',
            $color . '_RGB_COLOR_BLUE',
        );

        no strict 'refs';

        +{
            'cid'       => $color,
            'name'      => FuseBead::From::PNG::Const->$n_key,
            'hex_color' => FuseBead::From::PNG::Const->$hex_key,
            'rgb_color' => [
                FuseBead::From::PNG::Const->$r_key,
                FuseBead::From::PNG::Const->$g_key,
                FuseBead::From::PNG::Const->$b_key,
            ],
        };
    };
}

sub flatten {
    my $self = shift;

    $self->identifier; # Make sure it's generated

    my %hash;
    my @keys = qw(id color diameter meta);

    @hash{ @keys } = @{ $self }{ @keys };

    return \%hash;
}

=pod

=head1 NAME

FuseBead::From::PNG::Bead - A simple representation of a fuse bead

=head1 SYNOPSIS

  use FuseBead::From::PNG::Bead;

  my ($color) = ('BLACK');

  my $object = FuseBead::From::PNG::Bead->new(
      color  => $color,
      meta   => {} # Anything else we want to track
  );

  # Get at the data with accessors

=head1 DESCRIPTION

Representation of a FuseBead Bead plus additional meta data about that bead

=head1 USAGE

=head2 new

 Usage     : ->new()
 Purpose   : Returns FuseBead::From::PNG::Bead object

 Returns   : FuseBead::From::PNG::Bead object
 Argument  :
                color -> must be a valid color from L<FuseBead::From::PNG::Const>
                meta  -> a hashref of additional meta data for the instanciated bead
 Throws    : Dies if the color is invalid

 Comment   : Clobbers meta if it's not a valid hashref
 See Also  :

=head2 id

See identifier

=head2 identifier

 Usage     : ->identifier()
 Purpose   : Returns bead id, which is based on color

 Returns   : the indentifier. Format: <color>
 Argument  :
 Throws    :

 Comment   : Identifiers aren't necessarily unique, more than one bead could have the same identifier and different meta for instance
 See Also  :


=head2 color

 Usage     : ->color() or ->color($new_color)
 Purpose   : Returns color for the bead, optionally a new color may be set

 Returns   : color value for this bead
 Argument  : Optional. Pass a scalar with a new valid color value to change the beads color
 Throws    :

 Comment   :
 See Also  :

=head2 diameter

 Usage     : ->diameter() or ->diameter($new_number)
 Purpose   : Returns diameter for the bead, optionally a new diameter may be set

 Returns   : diameter value for this bead
 Argument  : Optional. Pass a scalar with a new valid diameter value to change the beads diameter
 Throws    :

 Comment   :
 See Also  :

=head2 meta

 Usage     : ->meta()
 Purpose   : Returns bead meta data

 Returns   : bead meta data
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 color_info

 Usage     : ->color_info()
 Purpose   : Returns hash of color info related to beads current color

 Returns   : hash of color info
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 flatten

 Usage     : ->flatten()
 Purpose   : Returns an unblessed version of the data

 Returns   : hashref of bead data
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
    https://github.com/gaudeon/FuseBead-From-Png

=head1 COPYRIGHT

This program is free software licensed under the...

    The MIT License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

1;
