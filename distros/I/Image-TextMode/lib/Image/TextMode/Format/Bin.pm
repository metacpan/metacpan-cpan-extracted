package Image::TextMode::Format::Bin;

use Moo;

extends 'Image::TextMode::Format', 'Image::TextMode::Canvas';

sub extensions { return 'bin' }

=head1 NAME

Image::TextMode::Format::Bin - read and write Bin files

=head1 DESCRIPTION

The Bin format is essentially a raw VGA video dump. It is a sequence of
character and attribute byte pairs. It holds no width information, so any
images over 80 columns will have to be described in an alternate way (i.e.
via SAUCE metadata).

=head1 METHODS

=head2 new( %args )

Creates a Bin instance.

=head2 extensions( )

Returns 'bin'.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2015 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
