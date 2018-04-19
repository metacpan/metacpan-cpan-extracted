package Graphics::Grid::Justifiable;

# ABSTRACT: Role for supporting positional justifications in Graphics::Grid

use Graphics::Grid::Role;

our $VERSION = '0.0001'; # VERSION

use Types::Standard qw(InstanceOf);
use Graphics::Grid::Types qw(:all);


has just => (
    is      => 'ro',
    isa     => Justification,
    coerce  => 1,
    default => sub { [ 0.5, 0.5 ] },    # center
);

has hjust => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_hjust',
    init_arg => undef,
);

has vjust => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_vjust',
    init_arg => undef,
);

sub _build_hjust { $_[0]->just->[0]; }
sub _build_vjust { $_[0]->just->[1]; }


method calc_left_bottom( $x, $y, $width, $height ) {
    my $left   = $x - $self->hjust * $width;
    my $bottom = $y - $self->vjust * $height;
    return ( $left, $bottom );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Justifiable - Role for supporting positional justifications in Graphics::Grid

=head1 VERSION

version 0.0001

=head1 DESCRIPTION

This role describes something that has "justification" which defines
how the object's exact position be determined and ajusted from its (x, y)
attributes.

=head1 ATTRIBUTES

=head2 just

The justification of the object, which consumes this role, relative to
its (x, y) location.

The value is an arrayref in the form of C<[$hjust, $vjust]>, where $hjust
and $vjust are two numbers for horizontal and vertical justification
respectively. Each number is usually from 0 to 1, but can also beyond 
hat range. 0 means left alignment and 1 means right alighment.

Default is C<[0.5, 0.5]>, which means the object's center is aligned to
its (x, y) position.

For example, for a rectangle which has $width and $height, and positioned
at ($x, $y), the position of its left-bottom corner can be calculated in
this way,

    $left   = $x - $hjust * $width;
    $bottom = $y - $vjust * $height;

This attribute also supports some string values. They map to numeric values
like below.

    string                          numeric
    ---------------------------     ------------
    left                            [ 0,   0.5 ]
    top                             [ 0.5, 1   ]
    right                           [ 1,   0.5 ]
    bottom                          [ 0.5, 0   ]
    center | centre                 [ 0.5, 0.5 ]
    bottom_left | left_bottom       [ 0,   0   ]
    top_left | left_top             [ 0,   1   ]
    bottom_right | right_bottom     [ 1,   0   ]
    top_right | right_top           [ 1,   1   ]

=head2 hjust

A reader accessor for the horizontal justification.

=head2 vjust

A reader accessor for vertical justification.

=head1 METHODS

=head2 calc_left_bottom($x, $y, $width, $height)

Calculate (left, bottom) position according to x, y, width and height.

=head1 SEE ALSO

L<Graphics::Grid>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
