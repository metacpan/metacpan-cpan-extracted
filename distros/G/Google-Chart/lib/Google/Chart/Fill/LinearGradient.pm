# $Id$

package Google::Chart::Fill::LinearGradient;
use Moose;
use Moose::Util::TypeConstraints;
use Google::Chart::Types;

with 'Google::Chart::Fill';

subtype 'Google::Chart::Fill::LinearGradient::Angle'
    => as 'Num'
    => where { $_ >= 0 && $_ <= 90 }
    => message { "Angle spec must be between 0 and 90" }
;

subtype 'Google::Chart::Fill::LinearGradient::Offset'
    => as 'Num'
    => where { $_ >= 0 && $_ <= 1 }
    => message { "Offset spec must be between 0 and 1" }
;

has 'target' => (
    is => 'rw',
    isa => enum([ qw(bc c) ]),
    default => 'bc',
    required => 1,
);

has 'angle' => (
    is => 'rw',
    isa => 'Google::Chart::Fill::LinearGradient::Angle',
    default => 0,
    required => 1
);

has 'color1' => (
    is => 'rw',
    isa => 'Google::Chart::Color::Data',
    required => 1
);

has 'color2' => (
    is => 'rw',
    isa => 'Google::Chart::Color::Data',
    required => 1
);

has 'offset1' => (
    is => 'rw',
    isa => 'Google::Chart::Fill::LinearGradient::Offset',
    default => 0,
    required => 1,
);

has 'offset2' => (
    is => 'rw',
    isa => 'Google::Chart::Fill::LinearGradient::Offset',
    default => 0,
    required => 1,
);

__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

sub parameter_value {
    my $self = shift;
    return join(",", $self->target, 'lg', $self->angle, $self->color1, $self->offset1, $self->color2, $self->offset2);
}

1;

__END__

=head1 NAME

Google::Chart::Fill::LinearGradient - Apply Gradient Fill

=head1 METHODS

=head2 parameter_value

=cut
