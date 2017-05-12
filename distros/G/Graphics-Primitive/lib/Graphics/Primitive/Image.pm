package Graphics::Primitive::Image;
use Moose;
use MooseX::Storage;

extends 'Graphics::Primitive::Component';

with qw(MooseX::Clone Graphics::Primitive::Aligned);
with Storage (format => 'JSON', io => 'File');

has image => (
    is => 'rw',
    isa => 'Str'
);
has scale => (
    is => 'rw',
    isa => 'ArrayRef',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
=head1 NAME

Graphics::Primitive::Image - Image component

=head1 DESCRIPTION

Graphics::Primitive::Image is a Component that displays in image.

=head1 SYNOPSIS

  use Graphics::Primitive::Image;

  my $img = Graphics::Primitive::Image->new(
      image => '/path/to/filename'
  );

=head1 WARNING

B<THIS COMPONENT IS EXPERIMENTAL.>

=head1 METHODS

=head2 Constructor

=over 4

=item I<new>

Creates a new Graphics::Primitive::Image.

=back

=head2 Instance Methods

=over 4

=item I<horizontal_alignment>

Set/Get the horizontal alignment of this component's image.

=item I<image>

Set/Get the filename of this components image.

=item I<vertical_alignment>

Set/Get the vertical alignment of this component's image.

=back

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 by Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.