# $Id$

package Google::Chart::Grid;
use Moose;
use Moose::Util::TypeConstraints;

use constant parameter_name => 'chg';

with 'Google::Chart::QueryComponent::Simple';

coerce 'Google::Chart::Grid'
    => from 'HashRef'
    => via {
        Google::Chart::Grid->new(%{$_});
    }
;


has 'x_step_size' => (
    is => 'rw',
    isa => 'Num',
    required => 1,
    default => 20,
);

has 'y_step_size' => (
    is => 'rw',
    isa => 'Num',
    required => 1,
    default => 20,
);

has 'line_length' => (
    is => 'rw',
    isa => 'Num',
    required => 1,
    default => 1,
);

has 'blank_length' => (
    is => 'rw',
    isa => 'Num',
    required => 1,
    default => 1,
);

__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

sub parameter_value {
    my $self = shift;
    return join(',', map { $self->$_ } qw(x_step_size y_step_size line_length blank_length));
}

1;

__END__

=head1 NAME

Google::Chart::Grid - Google::Chart Grid Specification 

=head1 METHODS

=head2 as_query

=cut
