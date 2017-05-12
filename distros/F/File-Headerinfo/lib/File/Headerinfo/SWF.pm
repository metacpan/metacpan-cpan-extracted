package File::Headerinfo::SWF;

use strict;
use base qw(File::Headerinfo);
use SWF::Header;

=head1 NAME

File::Headerinfo::SWF - an extractor of useful information from shockwave files.

=head1 DESCRIPTION

I<File::Headerinfo::SWF> uses SWF::Header to read the headers of .swf files and extract useful information like their duration, dimensions and framerate.

=cut

sub parse_file {
    my $self = shift;
    my $header = SWF::Header->read_file( $self->path );
    $self->filetype('swf');
    $self->width($header->{width});
    $self->height($header->{height});
    $self->duration($header->{duration});
    $self->fps($header->{rate});
    $self->filesize($header->{filelen});
    $self->version($header->{version});
}

=head1 COPYRIGHT

Copyright 2004 William Ross (wross@cpan.org)

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<File::Headerinfo>, L<SWF::Header>

=cut

1;
