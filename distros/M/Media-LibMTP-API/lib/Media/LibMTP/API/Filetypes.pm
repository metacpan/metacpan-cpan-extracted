#---------------------------------------------------------------------
package Media::LibMTP::API::Filetypes;
#
# Copyright 2011 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 18 Dec 2011
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Map extensions & MIME types to libmtp filetypes
#---------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

our $VERSION = '0.04';
# This file is part of Media-LibMTP-API 0.04 (May 31, 2014)

use Exporter 5.57 'import';     # exported import method
our @EXPORT_OK = qw(filetype filetype_from_path);

use Media::LibMTP::API ':filetypes';

#=====================================================================
sub _f
{
  my $type = shift;
  map { $_ => $type } @_;
} # end _f

our %typemap = (
  _f(LIBMTP_FILETYPE_WAV,        qw(wav audio/vnd.wave)),
  _f(LIBMTP_FILETYPE_MP3,        qw(mp3 audio/mpeg)),
  _f(LIBMTP_FILETYPE_WMA,        qw(wma audio/x-ms-wma)),
  _f(LIBMTP_FILETYPE_OGG,        qw(ogg oga audio/ogg audio/vorbis)),
  _f(LIBMTP_FILETYPE_AUDIBLE,    qw(aa)),
  _f(LIBMTP_FILETYPE_MP4,        qw(mp4 m4v video/mp4)),
  _f(LIBMTP_FILETYPE_WMV,        qw(wmv video/x-ms-wmv)),
  _f(LIBMTP_FILETYPE_AVI,        qw(avi)),
  _f(LIBMTP_FILETYPE_MPEG,       qw(mpg mpeg video/mpeg)),
  _f(LIBMTP_FILETYPE_ASF,        qw(asf)),
  _f(LIBMTP_FILETYPE_QT,         qw(qt mov video/quicktime)),
  _f(LIBMTP_FILETYPE_JPEG,       qw(jpg jpeg image/jpeg)),
  _f(LIBMTP_FILETYPE_JFIF,       qw(jfif)),
  _f(LIBMTP_FILETYPE_TIFF,       qw(tiff image/tiff)),
  _f(LIBMTP_FILETYPE_BMP,        qw(bmp)),
  _f(LIBMTP_FILETYPE_GIF,        qw(gif image/gif)),
  _f(LIBMTP_FILETYPE_PICT,       qw(pic pict)),
  _f(LIBMTP_FILETYPE_PNG,        qw(png image/png)),
  _f(LIBMTP_FILETYPE_VCALENDAR1, qw()),
  _f(LIBMTP_FILETYPE_VCALENDAR2, qw(ics)),
  _f(LIBMTP_FILETYPE_VCARD2,     qw()),
  _f(LIBMTP_FILETYPE_VCARD3,     qw(vcf text/vcard)),
  _f(LIBMTP_FILETYPE_WINDOWSIMAGEFORMAT, qw(wmf image/x-wmf)),
  _f(LIBMTP_FILETYPE_WINEXEC,    qw(exe com bat dll sys)),
  _f(LIBMTP_FILETYPE_TEXT,       qw(txt text/plain)),
  _f(LIBMTP_FILETYPE_HTML,       qw(htm html text/html)),
  _f(LIBMTP_FILETYPE_FIRMWARE,   qw(bin)),
  _f(LIBMTP_FILETYPE_AAC,        qw(aac)),
  _f(LIBMTP_FILETYPE_MEDIACARD,  qw()),
  _f(LIBMTP_FILETYPE_FLAC,       qw(flac fla audio/flac)),
  _f(LIBMTP_FILETYPE_MP2,        qw(mp2)),
  _f(LIBMTP_FILETYPE_M4A,        qw(m4a audio/mp4)),
  _f(LIBMTP_FILETYPE_DOC,        qw(doc application/msword)),
  _f(LIBMTP_FILETYPE_XML,        qw(xml text/xml)),
  _f(LIBMTP_FILETYPE_XLS,        qw(xls application/vnd.ms-excel)),
  _f(LIBMTP_FILETYPE_PPT,        qw(ppt application/vnd.ms-powerpoint)),
  _f(LIBMTP_FILETYPE_MHT,        qw(mht)),
  _f(LIBMTP_FILETYPE_JP2,        qw(jp2)),
  _f(LIBMTP_FILETYPE_JPX,        qw(jpx)),
);


sub filetype
{
  my $name = shift;

  $typemap{ lc $name } // LIBMTP_FILETYPE_UNKNOWN;
} # end filetype


sub filetype_from_path
{
  my ($path) = @_;

  if ($path =~ /\.([^.\/\\]+)\z/) {
    filetype($1);
  } else {
    LIBMTP_FILETYPE_UNKNOWN;
  }
} # end filetype_from_path

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

Media::LibMTP::API::Filetypes - Map extensions & MIME types to libmtp filetypes

=head1 VERSION

This document describes version 0.04 of
Media::LibMTP::API::Filetypes, released May 31, 2014
as part of Media-LibMTP-API version 0.04.

=head1 SYNOPSIS

  use Media::LibMTP::API::Filetypes qw(filetype filetype_from_path);

  $type = filetype('wav');       # File extension (sans '.')
  $type = filetype('audio/ogg'); # Internet media type
  $type = filetype_from_path('/tmp/song.mp3');

=head1 DESCRIPTION

Media::LibMTP::API::Filetypes provides two functions to map Internet
media types and/or file extensions to the filetype constants defined
by libmtp (C<LIBMTP_FILETYPE_*>).

=head1 SUBROUTINES

The following functions are exported only by request:

=head2 filetype

  $type = filetype($media_type_or_extension);

This takes a filename extension (without the C<.>) or an Internet
media type (e.g. C<audio/ogg>) and returns the corresponding libmtp
filetype constant.  If C<$media_type_or_extension> is not recognized,
then it returns C<LIBMTP_FILETYPE_UNKNOWN>.


=head2 filetype_from_path

  $type = filetype_from_path($filename);

This takes a filename (with or without directory names) and returns
the corresponding libmtp filetype constant (based on the filename's
extension only).  The file need not exist on disk.  If the filename's
extension is not recognized (or it has no extension at all), then it
returns C<LIBMTP_FILETYPE_UNKNOWN>.

=head1 CONFIGURATION AND ENVIRONMENT

Media::LibMTP::API::Filetypes requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Media-LibMTP-API AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Media-LibMTP-API >>.

You can follow or contribute to Media-LibMTP-API's development at
L<< https://github.com/madsen/media-libmtp-api >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
