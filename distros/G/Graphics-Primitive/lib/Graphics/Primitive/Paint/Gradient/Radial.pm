package Graphics::Primitive::Paint::Gradient::Radial;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Storage;

extends 'Graphics::Primitive::Paint::Gradient';

with Storage (format => 'JSON', io => 'File');

has 'end' => (
    is => 'rw',
    isa => 'Geometry::Primitive::Circle',
    required => 1
);
has 'start' => (
    is => 'rw',
    isa => 'Geometry::Primitive::Circle',
    required => 1
);

__PACKAGE__->meta->make_immutable;

no Moose;
1;
__END__
=head1 NAME

Graphics::Primitive::Paint::Gradient::Radial - Radial color blending

=head1 DESCRIPTION

Graphics::Primitive::Paint::Gradient::Radial is a color blend between two
circles.

=head1 SYNOPSIS

  use Graphics::Primitive::Paint::Gradient::Radial;

  my $gradient = Graphics::Primitive::Gradient::Radial->new(
      start => Geometry::Primitive::Circle->new(
          origin => 0, 0,
          radius => 5
      ),
      end => Geometry::Primitive::Circle->new(
          origin => 50, 25,
          radius => 5
      )
  );
  $gradient->add_stop(0.0, $color1);
  $gradient->add_stop(1.0, $color2);

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

=item I<end>

The "end" circle.

=item I<start>

The "start" circle.

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
