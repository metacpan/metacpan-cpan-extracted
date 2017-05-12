package Graphics::Primitive::Paint::Gradient;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Storage;

extends 'Graphics::Primitive::Paint';

# FIXME key should be <= 1
has color_stops => (
    traits => ['Hash'],
    isa => 'HashRef',
    is  => 'rw',
    default =>  sub { {} },
    handles => {
        stop_count => 'count',
        stops      => 'keys',
        get_stop   => 'get',
        add_stop   => 'set',
    }
);

__PACKAGE__->meta->make_immutable;

no Moose;
1;
__END__
=head1 NAME

Graphics::Primitive::Paint::Gradient - Color blending

=head1 DESCRIPTION

Graphics::Primitive::Paint::Gradient is a base class used by color blending
techniques such as linear and radial.  You should not use this class directly.

=head1 METHODS

=head2 Constructor

=over 4

=item I<new>

Creates a new Graphics::Primitive::Gradient

=back

=head2 Instance Methods

=over 4

=item I<add_stop>

Adds a color stop at the specified position

=item I<colors>

Hashref of colors and their stops.  The stops are the keys.

=item I<stop_count>

Count of stops added to this Gradient.

=item I<stops>

Get the keys of all color stops.

=back

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 by Cory G Watson.

You can redistribute and/or modify this code under the same terms as Perl
itself.
