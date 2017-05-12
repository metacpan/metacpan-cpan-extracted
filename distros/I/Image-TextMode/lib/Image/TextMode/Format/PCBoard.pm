package Image::TextMode::Format::PCBoard;

use Moo;

extends 'Image::TextMode::Format', 'Image::TextMode::Canvas';

sub extensions { return 'pcb' }

=head1 NAME

Image::TextMode::Format::PCBoard - read and write PCBoard files

=head1 DESCRIPTION

A PCBoard file is very much like an ANSI file. It uses C<@> as the "escape
sequence marker" and provides some basic variable substitution for items
delimited by C<@> on either end (e.g. C<@USER@>).

=head1 METHODS

=head2 new( %args )

Creates a PCBoard instance.

=head2 extensions( )

Returns 'pcb'.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2015 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
