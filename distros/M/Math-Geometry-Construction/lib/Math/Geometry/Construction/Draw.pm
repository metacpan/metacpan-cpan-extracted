package Math::Geometry::Construction::Draw;

use 5.008008;

use Moose;
use Carp;

=head1 NAME

C<Math::Geometry::Construction::Draw> - base class for drawing

=head1 VERSION

Version 0.022

=cut

our $VERSION = '0.022';


###########################################################################
#                                                                         #
#                      Class Variables and Methods                        # 
#                                                                         #
###########################################################################

###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

has 'output'            => (isa      => 'Item',
			    is       => 'rw',
			    writer   => '_output');

has ['width', 'height'] => (isa      => 'Str',
			    is       => 'ro',
			    required => 1);

has 'transform'         => (isa      => 'ArrayRef[Num]',
			    is       => 'ro',
			    default  => sub { [1, 0, 0, 1, 0, 0] });


###########################################################################
#                                                                         #
#                            Generate Output                              #
#                                                                         #
###########################################################################

sub is_flipped {
    my ($self) = @_;
    my $t      = $self->transform;

    return($t->[0] * $t->[3] - $t->[1] * $t->[2] <= 0 ? 1 : 0);
}

sub transform_coordinates {
    my ($self, $x, $y) = @_;
    my $t              = $self->transform;
    my $split          = qr/(.*?)(\s*[a-zA-Z]*)$/;

    my @x_parts = $x =~ $split;
    my @y_parts = $y =~ $split;

    my $xt = $t->[0] * $x_parts[0] + $t->[2] * $y_parts[0] + $t->[4];
    my $yt = $t->[1] * $x_parts[0] + $t->[3] * $y_parts[0] + $t->[5];

    return("$xt$x_parts[1]", "$yt$y_parts[1]");
}

sub transform_x_length {
    my ($self, $l) = @_;

    return(abs($l * $self->transform->[0]));
}

sub transform_y_length {
    my ($self, $l) = @_;

    return(abs($l * $self->transform->[3]));
}

sub line {}
sub circle {}
sub text {}


1;


__END__

=pod

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 INTERFACE

=head2 Public Attributes

=head2 Methods for Users

=head2 Methods for Subclass Developers

=head3 is_flipped

Returns the sign of the transformation matrix.

=head3 transform_coordinates

=head3 transform_x_length

=head3 transform_y_length

=head3 create_derived_point

=head3 as_svg

=head3 id_template


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011, 2013 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

