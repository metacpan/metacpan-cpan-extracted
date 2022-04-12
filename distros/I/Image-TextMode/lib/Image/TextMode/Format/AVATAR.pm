package Image::TextMode::Format::AVATAR;

use Moo;

extends 'Image::TextMode::Format', 'Image::TextMode::Canvas';

sub extensions { return 'avt' }

=head1 NAME

Image::TextMode::Format::AVATAR - read and write AVATAR files

=head1 DESCRIPTION

AVATAR stands for Advanced Video Attribute Terminal Assembler and Recreator. 
By using shorter, binary-based "escape codes" the AVATAR format generally
produces smaller files in comparison to ANSI-standard files.

=head1 METHODS

=head2 new( %args )

Creates a AVATAR instance.

=head2 extensions( )

Returns 'avt'.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
