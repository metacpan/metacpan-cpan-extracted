# $Id$

package Google::Chart::Fill::LinearStripes;
use Moose;
use Moose::Util::TypeConstraints;
use Google::Chart::Types;

with 'Google::Chart::Fill';

subtype 'Google::Chart::Fill::LinearStripes::Angle'
    => as 'Num'
    => where { $_ >= 0 && $_ <= 90 }
    => message { "Angle spec must be between 0 and 90" }
;

subtype 'Google::Chart::Fill::LinearStripes::StripeList'
    => as 'ArrayRef[Google::Chart::Fill::LinearStripes::Stripe]'
;

coerce 'Google::Chart::Fill::LinearStripes::StripeList'
    => from 'ArrayRef'
    => via {
        my @list;
        foreach my $h (@$_) {
            push @list, Google::Chart::Fill::LinearStripes::Strip->new(%$h);
        }
        return \@list;
    }
;

has 'target' => (
    is => 'rw',
    isa => enum([ qw(bc c) ]),
    required => 1,
);

has 'angle' => (
    is => 'rw',
    isa => 'Google::Chart::Fill::LinearStripes::Angle',
    required => 1
);

has 'stripes' => (
    is => 'rw',
    isa => 'Google::Chart::Fill::LinearStripes::StripeList',
    coerce => 1,
    required => 1,
    auto_deref => 1,
);

__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

sub parameter_value {
    my $self = shift;
    return join(",", $self->target, 'ls', $self->angle, 
        map { $_->as_query } $self->stripes )
}

package
    Google::Chart::Fill::LinearStripes::Stripe;
use Moose;
use Moose::Util::TypeConstraints;

with 'Google::Chart::QueryComponent';

subtype 'Google::Chart::Fill::LinearStripes::Stripe::Width'
    => as 'Num'
    => where { $_ > 0 && $_ <= 1 }
    => message { "Stripe width spec must be between 0 and 1" }
;


has 'color' => (
    is => 'rw',
    isa => 'Google::Chart::Color::Data',
    required => 1
);

has 'width' => (
    is => 'rw',
    isa => 'Google::Chart::Fill::LinearStripes::Strip::Width',
    required => 1
);

no Moose;
no Moose::Util::TypeConstraints;

sub as_query {
    my $self = shift;
    return join(',', $self->color, $self->width);
}

1;

__END__

=head1 NAME

Google::Chart::Fill::LinearStripes - Apply Linear Strip Fill

=head1 METHODS

=head2 parameter_value

=cut
