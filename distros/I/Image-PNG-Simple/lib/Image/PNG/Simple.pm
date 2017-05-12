package Image::PNG::Simple;

use 5.008007;
use strict;
use warnings;
use File::Temp ();
use Carp 'croak';

our $VERSION = '0.07';

require XSLoader;
XSLoader::load('Image::PNG::Simple', $VERSION);

sub parse_bmp_data {
  my ($self, $data) = @_;
  
  my $tmp_dir = File::Temp->newdir;
  my $tmp_file = "$tmp_dir/tmp.bmp";
  
  open my $out_fh, '>', $tmp_file
    or croak "Can't open file $tmp_file for write: $!";
  
  binmode $out_fh;
  print $out_fh $data;
  close $out_fh;
  
  $self->read_bmp_file($tmp_file);
}

sub get_bmp_data {
  my $self = shift;
  
  my $tmp_dir = File::Temp->newdir;
  my $tmp_file = "$tmp_dir/tmp.bmp";
  
  # Write bmp data to temp file
  open my $out_fh, '>', $tmp_file
    or croak "Can't open file $tmp_file for write: $!";
  $self->write_bmp_file($tmp_file);
  close $out_fh;
  
  # Read bmp data from temp file
  open my $in_fh, '<', $tmp_file
    or croak "Can't open file $tmp_file for read: $!";
  binmode($in_fh);
  my $bmp_data = do { local $/; <$in_fh> };
  close $in_fh;
  
  return $bmp_data;
}

sub get_png_data {
  my $self = shift;
  
  my $tmp_dir = File::Temp->newdir;
  my $tmp_file = "$tmp_dir/tmp.png";
  
  # Write png data to temp file
  open my $out_fh, '>', $tmp_file
    or croak "Can't open file $tmp_file for write: $!";
  $self->write_png_file($tmp_file);
  close $out_fh;
  
  # Read png data from temp file
  open my $in_fh, '<', $tmp_file
    or croak "Can't open file $tmp_file for read: $!";
  binmode($in_fh);
  my $png_data = do { local $/; <$in_fh> };
  close $in_fh;
  
  return $png_data;
}

1;

=head1 NAME

Image::PNG::Simple - Convert bitmap file to png file without C library dependency.

=head1 CAUTION

B<This is beta release. API will be changed without warnings.>

=head1 SYNOPSIS

  use Image::PNG::Simple;
  
  # Create Image::PNG::Simple object
  my $ips = Image::PNG::Simple->new;
  
  # Read bitmap file
  $ips->read_bmp_file('dog.bmp');
  
  # Write png file
  $ips->write_png_file('dog.png');

=head1 DESCRIPTION

Convert bitmap file to png file without C library dependency.

=head1 METHODS

=head2 new

  my $ips = Image::PNG::Simple->new;

Create new Image::PNG::Simple object.

=head2 read_bmp_file

  $ips->read_bmp_file('dog.bmp');

Read bitmap file.

=head2 parse_bmp_data

  $ips->parse_bmp_data($bmp_data);

Prase bitmap binary data.

=head2 get_bmp_data

  $ips->get_bmp_data;

Get bitmap binary data.

=head2 get_png_data

  $ips->get_png_data;
  
Get png binary data.

=head2 write_bmp_file

  $ips->write_bmp_file('dog_copy.bmp');

Write bitmap file.

=head2 write_png_file

  $ips->write_png_file('dog.png');

Write png file.

=head1 INTERNAL

This module internally use libpng-1.6.17 and zlib-1.2.8.
So This module license follow Perl license, libpng license and zlib license.

=head1 SEE ALSO

L<Image::PNG>, L<Imager::File::PNG>, L<Image::PNG::Libpng>

=head1 AUTHOR

Yuki Kimoto E<lt>kimoto.yuki@gmail.comE<gt>

=head1 REPOSITORY and BUG REPORT

Tell me on Github Repository

L<https://github.com/yuki-kimoto/Image-PNG-Simple>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Yuki Kimoto

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl, libpng, and zlib itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
