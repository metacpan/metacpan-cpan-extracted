package Image::Pbm;

our $VERSION = '0.04';

use strict;
use warnings;
use Image::Xbm(); our @ISA = 'Image::Xbm';
use Image::PBMlib 2.00 ();

sub load
{
  my $self = shift ;
  my $file = shift || $self->get(-file ) or die 'No file specified';

  open my $f, $file or die "Failed to open `$file': $!";
       my $h = {};
       my $p = [];
  Image::PBMlib::readpnmfile( $f, $h, $p,'dec');
  die "Failed to parse header in `$file': $h->{error}" if $h->{error};
  die "Wrong magic number: ($h->{type})" if $h->{type} != 1;

  $self->_set(  -file => $file );
  $self->_set( -width => $h->{width} );
  $self->_set(-height => $h->{height} );
  $self->_set(  -bits => pack 'b*', join '', map { @$_ } @$p );
}

sub save
{
  my $self = shift;
  my $file = shift || $self->get(-file ) or die 'No file specified';

  # I hate getter/setter! They may be helpful in languages
  # which fail to hide the implementation of properties.
  my ( $setch, $unsetch ) = $self->get(-setch,-unsetch );
  $self->set(-file => $file,-setch => ' 1',-unsetch => ' 0');

  open my $f, ">$file" or die "Failed to open `$file': $!";
  local $\ = "\n";
  print $f 'P1';
  print $f "# $file";
  print $f $self->get(-width );
  print $f $self->get(-height );
  print $f $self->as_string;

  $self->set(-setch => $setch,-unsetch => $unsetch );
}

1;

=head1 NAME

Image::Pbm - Load, create, manipulate and save pbm image files.

=head1 SYNOPSIS

  use Image::Pbm();

  my $i = Image::Pbm->new(-width => 50, -height => 25 );
  $i->line     ( 2, 2, 22, 22 => 1 );
  $i->rectangle( 4, 4, 40, 20 => 1 );
  $i->ellipse  ( 6, 6, 30, 15 => 1 );
  $i->xybit    (       42, 22 => 1 );
  print $i->as_string;
  $i->save('test.pbm');

  $i = Image::Pbm->new(-file,'test.pbm');

=head1 DESCRIPTION

This module provides basic load, manipulate and save functionality for
the pbm file format. It inherits from C<Image::Xbm> which provides additional
functionality.

See L<Image::Base> and L<Image::Xbm> for a description of all
inherited methods.

=head1 EXAMPLE

Imagine, we have to create self-contained web pages (with embedded images).
Most browsers understand the xbm image format, but generating xbm files
requires a certain effort (or a full fledged graphics software package).
On the other hand, generating pbm files is easy. Indeed, it's more likely
that you use your favorite text editor instead of Image::Pbm for that task.
Reading pbm files is slightly more difficult.
That's where the Image::[PX]bm modules come into play:

  use Image::Pbm();

  Image::Pbm->new(-file,'test.pbm')
    ->new_from_image('Image::Xbm')
      ->save('test.xbm');

Once we have xbm files, we can serve these images onto the Internet.
To embed these images into a web page, we can use the "data" URL scheme:

  http://www.ietf.org/rfc/rfc2397.txt

which requires the standard %xx hex encoding of URLs:

  use URI::Escape();

  my $data = URI::Escape::uri_escape( $xbm );

  print qq(<img src="data:image/x-xbitmap,$data">);

This works with Mozilla and Opera.
For Internet Explorer, we can use the following workaround:

  print <<"HTML";
  <pre id="xbm" style="display: none;">$xbm</pre>

  <script>
    function xbm() { return document.getElementById('xbm').innerHTML; }
  </script>

  <img src="javascript:xbm()">
  HTML

This works with Mozilla too.

=head1 TODO

Contact Mark Summerfield because the inheritance hierarchy

  Image::Pbm <: Image::Xbm <: Image::Base

is suboptimal and should look like

  Image::Xbm <:
                Image::Bitmap <: Image::Base
  Image::Pbm <:

=head1 AUTHOR

Steffen Goeldner <sgoeldner@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004, 2012 Steffen Goeldner. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<Image::Base>, L<Image::Xbm>, L<Image::PBMlib>.

=cut
