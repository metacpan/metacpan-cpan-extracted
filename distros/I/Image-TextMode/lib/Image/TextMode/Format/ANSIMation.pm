package Image::TextMode::Format::ANSIMation;

use Moo;

extends 'Image::TextMode::Format', 'Image::TextMode::Animation';

use Image::TextMode::Palette::ANSI;

has '+palette' => ( default => sub { Image::TextMode::Palette::ANSI->new } );

sub extensions { return }

=head1 NAME

Image::TextMode::Format::ANSIMation - read and write ANSIMation files

=head1 DESCRIPTION

ANSIMation is an pseudo-format whereby the ANSI is displayed at a slow
enough rate so that it appears to animate the image. This module simulates
this by assuming a C<position(0,0)> command is the start of a new "frame" in
the sequence.

=head1 METHODS

=head2 new( %args )

Creates a ANSIMation instance.

=head2 extensions( )

Returns an empty list.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
