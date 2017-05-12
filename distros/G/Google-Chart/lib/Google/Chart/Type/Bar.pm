# $Id$

package Google::Chart::Type::Bar;
use Moose;
use Moose::Util::TypeConstraints;

with 'Google::Chart::Type::Simple';

enum 'Google::Chart::Type::Bar::Orientation' => qw(horizontal vertical);

has 'stacked' => (
    is => 'rw',
    isa => 'Bool',
    required => 1,
    default => 1,
);

has 'orientation' => (
    is => 'rw',
    isa => 'Google::Chart::Type::Bar::Orientation',
    required => 1,
    default => 'vertical',
);

__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

sub parameter_value {
    my $self = shift;

    return sprintf( 'b%s%s', 
        $self->orientation eq 'vertical' ? 'v' : 'h',
        $self->stacked                   ? 's' : 'g'
    );
}

1;

__END__

=head1 NAME

Google::Chart::Type::Bar - Google::Chart Bar Type

=head1 SYNOPSIS

  Google::Chart->new(
    type => {
      module => "Bar",
      orientation => "horizontal",
    }
  );

=head1 METHODS

=head2 parameter_value

=cut