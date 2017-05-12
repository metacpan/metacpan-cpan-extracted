#!/usr/bin/perl
#
# copyright (c) 2005, Eric Rollins, all rights reserved, worldwide
#
#

use strict;
use warnings;

package Genezzo::RawIO;
use Inline 'C';
require Exporter;

Inline->init; # help for "require RawIO"

our @ISA = qw(Exporter);
our @EXPORT = qw(gnz_raw_read gnz_raw_write);

sub gnz_raw_read(*\$$)
{
    my ($filehandle, $scalar, $length) = @_;
    
#    return sysread($filehandle, $$scalar, $length);
    return rawread($filehandle, $$scalar, $length);
}

sub gnz_raw_write(*$$)
{
    my ($filehandle, $scalar, $length) = @_;

#    return syswrite($filehandle, $scalar, $length);
    return rawwrite($filehandle, $scalar, $length);
}

1;

__DATA__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::RawIO - Genezzo Raw IO

=head1 SYNOPSIS

 Additional file read and write routines for Genezzo.

=head1 DESCRIPTION

 sysread and syswrite are wrapped by gen_raw_read and gen_raw_write 
 so raw devices can be used.

=head1 FUNCTIONS

=over 4

=item gen_raw_read FILEHANDLE, SCALAR, LENGTH

 Performs read identical to sysread, except uses aligned buffer 
 suitable for raw I/O.

=item gen_raw_write FILEHANDLE, SCALAR, LENGTH

 Performs write identical to syswrite, except uses aligned buffer 
 suitable for raw I/O.

=back

=head2 EXPORT

 gen_raw_read, gen_raw_write

=head1 LIMITATIONS

 Relies on Perl Inline::C module.  Code may gracefully compile to 
 empty stubs on non-raw (non-Linux) platforms, but this has not 
 been thoroughly tested.

=head1 AUTHOR

Eric Rollins, rollins@acm.org

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2005 Eric Rollins.  All rights reserved.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

Address bug reports and comments to rollins@acm.org

For more information, please visit the Genezzo homepage 
at L<http://www.genezzo.com>

=cut

__C__

#include <stdlib.h>
#include <unistd.h>
#include <string.h>

SV* rawread(PerlIO *fp, SV* buf, int count){
#ifdef _GNU_SOURCE 
  int bytes_read = 0;
  int fd = PerlIO_fileno(fp);
  char *align_buf = 0;
  posix_memalign(&align_buf,count,count);
  bytes_read = read(fd,align_buf,count);

  if(bytes_read != -1){
    sv_setpvn(buf, align_buf, count);
  }

  free(align_buf);

  if(bytes_read != -1){
    return newSViv(bytes_read);
  }

#endif

  return newSV(0);
}


SV* rawwrite(PerlIO *fp, SV* buf, int count){
#ifdef _GNU_SOURCE
  char *align_buf = 0;
  posix_memalign(&align_buf,count,count);
  int fd = PerlIO_fileno(fp);
  int buf_len;
  char *buf_contents = SvPV(buf, buf_len);
  // assert(count == buf_len);
  memcpy(align_buf,buf_contents, count);
  int bytes_written = write(fd, align_buf, count);
  free(align_buf);

  if(bytes_written != -1){
    return newSViv(bytes_written);
  }

#endif

  return newSV(0);
}

