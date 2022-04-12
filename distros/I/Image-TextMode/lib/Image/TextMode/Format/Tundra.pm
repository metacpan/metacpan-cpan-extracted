package Image::TextMode::Format::Tundra;

use Moo;
use Types::Standard qw( HashRef );

extends 'Image::TextMode::Format', 'Image::TextMode::Canvas';

has 'header' => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { { int_id => 24, id => 'TUNDRA24' } }
);

has '+render_options' => ( default => sub { { truecolor => 1 } } );

sub extensions { return 'tnd' }

=head1 NAME

Image::TextMode::Format::Tundra - read and write Tundra files

=head1 DESCRIPTION

The Tundra format.

=head1 ACCESSORS

=over 4

=item * header - A header hashref containing a version number and id

=back

=head1 METHODS

=head2 new( %args )

Creates a Tundra instance.

=head2 extensions( )

Returns 'tnd'.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
