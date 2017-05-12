package Graphics::Primitive::Operation::Fill;
use Moose;
use MooseX::Storage;

extends 'Graphics::Primitive::Operation';

with 'MooseX::Clone';
with Storage (format => 'JSON', io => 'File');

has paint => (
    isa => 'Graphics::Primitive::Paint',
    is  => 'rw',
    required => 1,
    traits => [qw(Clone)]
);

__PACKAGE__->meta->make_immutable;

no Moose;
1;
__END__
=head1 NAME

Graphics::Primitive::Operation::Fill - Paint inside a path

=head1 DESCRIPTION

Graphics::Primitive::Operation::Fill represents a fill operation to be
performed on a path.

=head1 SYNOPSIS

  use Graphics::Primitive::Operation::Fill;

  my $fill = Graphics::Primitive::Operation::Fill->new;
  $fill->paint(Graphics::Primitive::Paint::Solid->new);

=head1 METHODS

=head2 Constructor

=over 4

=item I<new>

Creates a new Graphics::Primitive::Operation::Fill.

=back

=head2 Instance Methods

=over 4

=item I<paint>

Set/Get the L<Paint|Graphics::Primitive::Paint> to use for this fill.

=back

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 by Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.