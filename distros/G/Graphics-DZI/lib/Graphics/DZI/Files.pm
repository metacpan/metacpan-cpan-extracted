package Graphics::DZI::Files;

use warnings;
use strict;

use Moose;
extends 'Graphics::DZI';

our $log;
use Log::Log4perl;
BEGIN {
    $log = Log::Log4perl->get_logger ();
}

=head1 NAME

Graphics::DZI::Files - DeepZoom Image Pyramid Generation, File-based

=head1 SYNOPSIS

  use Graphics::DZI::Files;
  my $dzi = new Graphics::DZI::Files (image    => $image,
				      overlap  => 4,
				      tilesize => 256,
				      scale    => 2,
 				      format   => 'png',
                                      prefix   => 'xxx',
                                      path     => '/where/ever/');
  use File::Slurp;
  write_file ('/where/ever/xxx.xml', $dzi->descriptor);
  $dzi->iterate ();

  # since 0.05
  use Graphics::DZI::Files;
  my $dzi = new Graphics::DZI::Files (image => $image,
	  			      dzi   => '/tmp/xxx.dzi');


=head1 DESCRIPTION

This subclass of L<Graphics::DZI> generates tiles and stores them at the specified path location.

=head1 INTERFACE

=head2 Constructor

Additional to the parent class L<Graphics::DZI>, the constructor takes the following fields:

=over

=item C<format> (default C<png>):

An image format (C<png>, C<jpg>, ...). Any format L<Image::Magick> understands will do.

=item C<path>: (deprecated from 0.05 onwards, use C<dzi>)

A directory name (including trailing C</>) where the tiles are written to. This has to include the
C<_files> part required by the DZI format.

=item C<prefix>: (deprecated from 0.05 onwards, use C<dzi>)

The string to be prefixed the C<_files/> part in the directory name. Usually the name of the image
to be converted. No slashes.

=item C<dzi> (since 0.05)

Alternatively to specifying the path and the prefix separately, you can also provide the full path
to the DZI file, say, C</var/www/photo.dzi>. The tiles will be written to
C</var/www/photo_files>.

=back

=cut

#has 'format'   => (isa => 'Str'   ,        is => 'ro', default => 'png');
has 'path'    => (isa => 'Str'   ,        is => 'ro');
has 'prefix'  => (isa => 'Str'   ,        is => 'ro');
has 'dzi'     => (isa => 'Str'   ,        is => 'ro');

=head2 Methods

=over

=item B<generate>

(since 0.05)

This method generates everything, the tiles and the XML descriptor. If you have specified a C<dzi>
field in the constructor, then you do not need to specify it as parameter. If you have used the
C<path>/C<prefix>, then you need to provide the full path.

=cut

sub generate {
    my $self = shift;

    my $dzifile = $self->dzi || shift;
    use File::Slurp;
    write_file ($dzifile, $self->descriptor);

    $self->iterate;
}

=item B<manifest>

This method writes any tile to a file, appropriately named for DZI inclusion.

=cut

sub manifest {
    my $self  = shift;
    my $tile  = shift;
    my $level = shift;
    my $row   = shift;
    my $col   = shift;

    my $path;
    if ($self->dzi) {
	$self->dzi =~ m{^(.+)\.(dzi|xml)$};
	$path = $1 . "_files/$level/";
    } else {
	$path = $self->path . "$level/";
    }
    use File::Path qw(make_path);
    make_path ($path);

    my $filen = $path . (sprintf "%s_%s", $col, $row ) . '.' . $self->format;
    $log->debug ("saving tile $level $row $col --> $filen");
    $tile->Write( $filen );
}

=back

=head1 AUTHOR

Robert Barta, C<< <drrho at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

our $VERSION = '0.02';
"against all odds";
