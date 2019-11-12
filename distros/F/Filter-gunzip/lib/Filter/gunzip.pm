# Copyright 2010, 2011, 2013, 2014, 2019 Kevin Ryde

# This file is part of Filter-gunzip.
#
# Filter-gunzip is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Filter-gunzip is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Filter-gunzip.  If not, see <http://www.gnu.org/licenses/>.

package Filter::gunzip;
use strict;
use Carp;
use DynaLoader;

use vars qw($VERSION @ISA);
$VERSION = 8;
@ISA = ('DynaLoader');

# uncomment this to run the ### lines
# use Smart::Comments;

my $use_xs = 1;
if (! eval { __PACKAGE__->bootstrap($VERSION) }) {
  ### filter gunzip no XS: $@
  $use_xs = 0;
} elsif (! eval { require PerlIO::gzip; 1 }) {
  ### filter gunzip have XS but no have PerlIO gzip: $@
  $use_xs = 0;
}

sub import {
  my ($class) = @_;
  if ($use_xs && _filter_by_layer()) {
    ### applied gzip layer ...
  } else {
    ### use Filter gunzip Filter ...
    require Filter::gunzip::Filter;
    Filter::gunzip::Filter->import;
  }
}

1;
__END__

=for stopwords gunzip Filter-gunzip uncompresses gzipped self-uncompressing gunzipping CRLF gzip CRC checksum zlib unbuffered Ryde

=head1 NAME

Filter::gunzip - gunzip Perl source code for execution

=head1 SYNOPSIS

 perl -MFilter::gunzip foo.pl.gz

 # or in a script
 use Filter::gunzip;
 ... # inline gzipped source code bytes

=head1 DESCRIPTION

This filter uncompresses gzipped Perl source code at run-time.  It can be
used from the command-line to run a F<.pl.gz> file,

    perl -MFilter::gunzip foo.pl.gz

Or in a self-uncompressing executable beginning with a C<use Filter::gunzip>
then gzip bytes immediately following that line,

    #!/usr/bin/perl
    use Filter::gunzip;
    ... raw gzip bytes here

The filter is implemented in one of two ways.

=over

=item *

If there are no other filters and PerlIO is available (now usual) then push
a C<PerlIO::gzip> layer.

=item *

Otherwise add a block-oriented source filter per L<perlfilter>.

=back

In both cases, the compressed code executed can apply further source filters
in usual ways.

=head2 DATA Handle

The C<__DATA__> token (see L<perldata/Special Literals>) and C<DATA> handle
can be used in the compressed source, but only some of the time.

For the C<PerlIO::gzip> case, the C<DATA> handle is simply the input,
including the C<:gzip> uncompressing layer, positioned just after the
C<__DATA__> token.  It can be read in the usual way.  However
C<PerlIO::gzip> as of its version 0.19 cannot C<dup()> or C<seek()>, which
limits what can be done with the C<DATA> handle.  In particular for example
C<SelfLoader> requires C<seek()> and so doesn't work on compressed source.
(Duping and seeking in C<PerlIO::gzip> are probably both feasible, though
seeking backward could be slow.)

For the L<perlfilter> case, C<DATA> doesn't work properly.  Perl stops
reading from the source filters at the C<__DATA__> token, because that's
where the source ends.  But a block oriented filter like C<Filter::gunzip>
may read ahead in the input file which means the position of the C<DATA>
handle is unpredictable, especially if there's more than one block-oriented
filter stacked up.

=head2 CRLF

If C<Filter::gunzip> sees a C<:crlf> layer on top of the input then it
pushes C<:gzip> underneath that, since the CRLF is almost certainly meant to
apply to the text, not to the raw gzip bytes.  In particular this should let
it work with the global C<PERLIO=crlf> (see L<perlrun/"PERLIO">) suggested
by F<README.cygwin>, and which you could conceivably use elsewhere too.

The Perl tokenizer has some of its own CRLF understanding (unless a
build-time strictness option is used) so it can normally read source code in
either CRLF or binary (and it translates any CRLF in literal strings or here
documents to newline).  This allows the default read mode to be chosen
according to what you might need for reading text files, including C<DATA>
parts of source files.

=head2 Read Errors

The gzip format has a CRC checksum at the end of the data.  This might catch
subtle corruption in the compressed bytes, but as of Perl 5.10 the parser
usually doesn't report a read error from the source and in any case the code
is compiled and C<BEGIN> blocks are executed immediately, before the CRC is
reached, so corruption will likely provoke a syntax error or similar first.

Only the gzip format (RFC 1952) is supported.  Zlib format (RFC 1950)
differs only in the header, but C<PerlIO::gzip> (version 0.18) doesn't allow
it.  The actual C<gunzip> program can handle some other formats too, like
Unix F<.Z> C<compress>, but those formats are probably best left to other
modules.

=head1 OTHER WAYS TO DO IT

C<Filter::exec> and the C<zcat> program can do the same thing, either from
the command line or self-expanding,

    perl -MFilter::exec=zcat foo.pl.gz

Because C<Filter::exec> is a block-oriented filter (as of its version 1.37)
a compressed C<DATA> section within the script doesn't work, the same as it
doesn't in the filter method here.

In the past it was possible to apply C<PerlIO::gzip> to a script with the
C<open> pragma and a C<require> of the script filename, though circa Perl
5.30 this doesn't seem to work any more.  It was something like the
following from the command line.  Since the C<open> pragma is lexical, it
doesn't affect other later loads or opens.

    perl -e '{use open IN=>":gzip";require shift}' \
            ./foo.pl.gz arg1 arg2

It doesn't work to set a C<PERLIO> environment variable for a global
C<:gzip> layer, like C<PERLIO=':gzip(autopop)'>, because such default layers
are restricted to Perl builtin layers (see L<perlrun/PERLIO>), and
C<PerlIO::gzip> is not a builtin.

Bzip2, lz, or other compression formats could be handled by a very similar
filter module.  Bz2 has the disadvantage of its decompressor using at least
2.5 Mbytes of memory, so there'd have to be a big disk saving before it was
worth that much memory at runtime.  C<Filter::exec> above can be used for
other formats since the various compression tools normally offer something
similar to C<zcat>, such as C<bzcat> or C<lzcat>, or equivalent command line
options as for example in C<lz4>.

=head1 BUGS

Gzip format has an end of data indication (cf the CRC described above).
Reading stops at that point, and it should be end of file too.  Behaviour is
unspecified if there's anything after.  The C<gunzip> program will read
multiple gzips which have been concatenated together, and uncompresses them
as a single stream.  Maybe similar would be helpful, or maybe something cute
like returning to plain text after the gzip.  Suspect C<PerlIO::gzip> treats
end of gzip as end of file, and so ignores anything after.  For now think
either concats or more text should be unusual and probably better handled
other ways.

=head1 SEE ALSO

L<PerlIO::gzip>, L<PerlIO>, L<Filter::Util::Call>, L<Filter::exec>,
L<gzip(1)>, L<zcat(1)>, L<open>

The author's C<compile-command-default.el> can setup Emacs to run a visited
C<.pl.gz> by either C<Filter::gunzip> or other ways, according to what's
available.

=over

L<http://user42.tuxfamily.org/compile-command-default/index.html>

=back

=head1 HOME PAGE

L<http://user42.tuxfamily.org/filter-gunzip/index.html>

=head1 LICENSE

Filter-gunzip is Copyright 2010, 2011, 2013, 2014, 2019 Kevin Ryde

Filter-gunzip is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Filter-gunzip is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Filter-gunzip.  If not, see <http://www.gnu.org/licenses/>.

=cut
