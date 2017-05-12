# $Id$

package Google::Chart::Fill::Solid;
use Moose;
use Moose::Util::TypeConstraints;
use Google::Chart::Types;

with 'Google::Chart::Fill';

has 'color' => (
    is => 'rw',
    isa => 'Google::Chart::Color::Data',
    required => 1,
);

has 'target' => (
    is => 'rw',
    isa => enum([ qw(bg c a) ]),
    required => 1
);

__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

sub parameter_value {
    my $self = shift;
    return join(',', $self->target, 's', $self->color)
}

1;

__END__

=head1 NAME

Google::Chart::Fill::Solid - Apply Solid Fill

=head1 SYNOPSIS

  use Google::Chart;
  Google::Chart->new(
    fill => {
      args => {
        color => "ffccff",
        target => "bg",
      }
    }
  );

  Google::Chart->new(
    fill => Google::Chart::Fill::Solid->new(
      color => "ffcff",
      target => "bg"
    )
  );

=cut
