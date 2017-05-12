# $Id$

package Google::Chart::Type::Pie;
use Moose;
use Moose::Util::TypeConstraints;

with 'Google::Chart::Type::Simple';

has 'pie_type' => (
    is => 'rw',
    isa => enum([ qw(2d 3d) ]),
    required => 1,
    default => '2d'
);

__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

sub parameter_value {
    my $self = shift;

    return $self->pie_type eq '3d' ? 'p3' : 'p';
}

1;

__END__

=head1 NAME

Google::Chart::Type::Pie - Google::Chart Pie Chart Type

=head1 SYNOPSIS

  Google::Chart->new(
    type => 'Pie'
  );

  Google::Chart->new(
    type => {
      module => 'Pie',
      args   => {
        pie_type => '3d'
      }
    }
  );

=head1 METHODS

=head2 parameter_value

=cut