package Graphics::Primitive::Paint::Gradient::Linear;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Storage;

extends 'Graphics::Primitive::Paint::Gradient';

with Storage (format => 'JSON', io => 'File');

has line => (
    isa => 'Geometry::Primitive::Line',
    is => 'rw',
);

__PACKAGE__->meta->make_immutable;

no Moose;
1;
__END__
=head1 NAME

Graphics::Primitive::Paint::Gradient::Linear - Linear color blending

=head1 DESCRIPTION

Graphics::Primitive::Paint::Gradient::Linear is a gradient along a line.

=head1 SYNOPSIS

  use Graphics::Primitive::Paint::Gradient::Linear;

  my $gradient = Graphics::Primitive::Gradient::Linear->new(
      line => Geometry::Primitive::Line->new(
          start => Graphics::Primitive::Point->new(x => 0, y => 0),
          end   => Graphics::Primitive::Point->new(x => 0, y => 10),
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

=item I<line>

The line along which the gradient should run.

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
