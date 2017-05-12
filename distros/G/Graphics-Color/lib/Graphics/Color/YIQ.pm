package Graphics::Color::YIQ;
$Graphics::Color::YIQ::VERSION = '0.31';
use Moose;
use MooseX::Aliases;

extends qw(Graphics::Color);

# ABSTRACT: YIQ color space


has 'luminance' => (
    is => 'rw',
    isa => 'Num',
    default => 1,
    alias => 'y'
);


has 'in_phase' => (
    is => 'rw',
    isa => 'Num',
    default => 1,
    alias => 'i'
);


has 'quadrature' => (
    is => 'rw',
    isa => 'Num',
    default => 1,
    alias => 'q'
);


has 'name' => ( is => 'rw', isa => 'Str' );


sub as_string {
    my ($self) = @_;

    return sprintf('%s,%s,%s',
        $self->luminance, $self->in_phase, $self->quadrature
    );
}


sub as_array {
    my ($self) = @_;

    return ($self->luminance, $self->in_phase, $self->quadrature);
}


sub equal_to {
    my ($self, $other) = @_;

    return 0 unless defined($other);

    unless($self->luminance == $other->luminance) {
        return 0;
    }
    unless($self->in_phase == $other->in_phase) {
        return 0;
    }
    unless($self->quadrature == $other->quadrature) {
        return 0;
    }

    return 1;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Graphics::Color::YIQ - YIQ color space

=head1 VERSION

version 0.31

=head1 SYNOPSIS

    use Graphics::Color::YIQ;

    my $color = Graphics::Color::YIQ->new({
        luminance   => 0.5,
        in_phase    => .5,
        quadrature  => .25,
    });

=head1 DESCRIPTION

Graphics::Color::YIQ represents a Color in an YIQ color space.

=head1 DISCLAIMER

I couldn't find clear information on the bounds of each value, so at the
moment there are none.

=head1 ATTRIBUTES

=head2 luminance

=head2 y

Set/Get the luminance component of this Color.

=head2 in_phase

=head2 i

Set/Get the in_phase component of this Color.

=head2 quadrature

=head2 q

Set/Get the quadrature component of this Color.

=head2 name

Get the name of this color.  Only valid if the color was created by name.

=head2 not_equal_to

The opposite of equal_to.

=head1 METHODS

=head2 as_string

Get a string version of this Color in the form of
LUMINANCE,IN-PHASE,QUADRATURE

=head2 as_array

Get the YIQ values as an array

=head2 equal_to

Compares this color to the provided one.  Returns 1 if true, else 0;

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
