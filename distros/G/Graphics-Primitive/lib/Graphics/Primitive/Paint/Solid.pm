package Graphics::Primitive::Paint::Solid;
use Moose;
use MooseX::Storage;

extends 'Graphics::Primitive::Paint';

with qw(MooseX::Clone);
with Storage (format => 'JSON', io => 'File');

has color => (
    isa => 'Graphics::Color',
    is  => 'rw',
    traits => [qw(Clone)]
);

__PACKAGE__->meta->make_immutable;

no Moose;
1;
=head1 NAME

Graphics::Primitive::Paint::Solid - Solid patch of color

=head1 DESCRIPTION

Graphics::Primitive::Paint::Solid represents a solid color.

=head1 SYNOPSIS

  use Graphics::Primitive::Paint::Solid;

  my $solid = Graphics::Primitive::Solid->new;
  $solid->color(Graphics::Color::RGB->new(red => 1, green => 0, blue => 0));

=head1 METHODS

=head2 Constructor

=over 4

=item I<new>

Creates a new Graphics::Primitive::Solid

=back

=head2 Instance Methods

=over 4

=item I<color>

Get/Set the color of this solid

=back

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 by Cory G Watson.

You can redistribute and/or modify this code under the same terms as Perl
itself.
