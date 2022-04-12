package Image::TextMode;

use strict;
use warnings;

our $VERSION = '0.26';

=head1 NAME

Image::TextMode - Create, manipulate and save text mode images

=head1 SYNOPSIS

    # load and rasterize an ANSI
    use Image::TextMode::Format::ANSI;
    use Image::TextMode::Renderer::GD;
    
    my $ansi = Image::TextMode::Format::ANSI->new;
    $ansi->read( $file );
    
    my $renderer = Image::TextMode::Renderer::GD->new;
    print $renderer->fullscale( $ansi );

=head1 DESCRIPTION

This set of modules provides the basic structure to represent a text mode
image such as an ANSI file.

=head1 TODO

=over 4

=item * better documentation

=item * flesh out and optimize write() methods

=item * better guessing techniques in the loader

=back

=head1 SEE ALSO

=over 4

=item * L<Image::TextMode::Format::ADF>

=item * L<Image::TextMode::Format::ANSI>

=item * L<Image::TextMode::Format::ANSIMation>

=item * L<Image::TextMode::Format::AVATAR>

=item * L<Image::TextMode::Format::Bin>

=item * L<Image::TextMode::Format::IDF>

=item * L<Image::TextMode::Format::PCBoard>

=item * L<Image::TextMode::Format::Tundra>

=item * L<Image::TextMode::Format::XBin>

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
