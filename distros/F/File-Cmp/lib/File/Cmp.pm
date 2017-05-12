# -*- Perl -*-
#
# Compare two files character by character like cmp(1).

package File::Cmp;

use 5.008000;
use strict;
use warnings;

use Carp qw/croak/;
use Scalar::Util qw/reftype/;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw/&fcmp/;

our $VERSION = '1.07';

# XXX 'skip' and 'limit' might be good parameters to add, to skip X
# initial bytes, limit work to Y bytes of data to check
sub fcmp {
  croak 'fcmp needs two files' if @_ < 2;
  my @files = splice @_, 0, 2;
  my $param = ( @_ == 1 and ref $_[0] eq 'HASH' ) ? $_[0] : {@_};

  $param->{sizecheck} = 1 unless exists $param->{sizecheck};
  $param->{sizecheck} = 0 if exists $param->{tells};

  if ( $param->{fscheck} ) {
    my @statbuf;
    for my $f (@files) {
      # stat has the handy property of chasing symlinks for us
      my @devino = ( stat $f )[ 0, 1 ] or croak "could not stat: $!";
      push @statbuf, \@devino;
    }
    if (  $statbuf[0][0] == $statbuf[1][0]
      and $statbuf[0][1] == $statbuf[1][1] ) {
      ${ $param->{reason} } = 'fscheck' if exists $param->{reason};
      return 1;    # assume files identical as both dev and inode match
    }
  }

  # The files are probably not identical if they differ in size;
  # however, offer means to turn this check off if -s for some reason is
  # incorrect (or if 'tells' is on so we need to find roughly where the
  # difference is in the files).
  if ( $param->{sizecheck} and -s $files[0] != -s $files[1] ) {
    ${ $param->{reason} } = 'size' if exists $param->{reason};
    return 0;
  }

  my @fhs;
  for my $f (@files) {
    if ( !defined reftype $f) {
      open my $fh, '<', $f or croak "could not open $f: $!";
      push @fhs, $fh;
    } else {
      # Assume is a GLOB or something can readline on, XXX might want to
      # better check this
      push @fhs, $f;
    }
    if ( exists $param->{binmode} ) {
      binmode $fhs[-1], $param->{binmode} or croak "binmode failed: $!";
    }
  }

  local $/ = $param->{RS} if exists $param->{RS};

  while (1) {
    my $eof1 = eof $fhs[0];
    my $eof2 = eof $fhs[1];
    # Done if both files are at EOF; otherwise assume they differ if one
    # completes before the other (this second case would normally be
    # optimized away by the -s test, above).
    last if $eof1 and $eof2;
    if ( $eof1 xor $eof2 ) {
      ${ $param->{reason} } = 'eof' if exists $param->{reason};
      @{ $param->{tells} } = ( tell $fhs[0], tell $fhs[1] )
        if exists $param->{tells};
      return 0;
    }

    my $this = readline $fhs[0];
    croak "error reading from first file: $!" if !defined $this;
    my $that = readline $fhs[1];
    croak "error reading from second file: $!" if !defined $that;

    if ( $this ne $that ) {
      @{ $param->{tells} } = ( tell $fhs[0], tell $fhs[1] )
        if exists $param->{tells};
      ${ $param->{reason} } = 'diff' if exists $param->{reason};
      return 0;
    }
  }

  return 1;    # assume files identical if get this far
}

1;
__END__

=head1 NAME

File::Cmp - compare two files character by character

=head1 SYNOPSIS

  use File::Cmp qw/fcmp/;

  print "identical" if fcmp("/tmp/foo", "/tmp/bar");

  fcmp(
    $fh1, $fh2,
    binmode   => ':raw',  # a good default
    fscheck   => 1,       # ... but beware network fs/portability
    RS        => \"4096"  # handy for binary
  );

Among other optional parameters.

=head1 DESCRIPTION

This module offers a B<fcmp> function that checks whether the contents
of two files are identical, in the spirit of the Unix L<cmp(1)> utility.
A single subroutine, B<fcmp>, is offered for optional export. It expects
at minimum two files or file handles, along with various optional
parameters following those filenames. Any errors encountered will cause
an exception to be thrown; consider C<eval> or L<Try::Tiny> to catch
these. Otherwise, the return value will be true if the files are
identical, false if not.

Note that if passed a file handle, the code will read to the end of the
handle, and will not rewind. This will require C<tell> and C<seek>
function calls before and after B<fcmp> to return to the same position,
if necessary. Likewise, if entire file contents are to be compared, file
handles may need C<SEEK_SET> performed on them to move to the beginning
prior to the B<fcmp> call. None of this is a concern if file names are
passed instead of file handles.

C<readline> calls are used on the filehandle. This means the usual "do
not mix sys* and non-sys* calls on the same filehandle" advice applies
for any passed filehandles. (See the C<sysread> function perldocs for
details in L<perlfunc>.)

Available parameters include:

=over 4

=item I<binmode>

If set, applied as the C<LAYER> specification of a C<binmode> call
performed on the files or file handles. C<:raw> may very well likely be
prudent for most cases, to avoid wasting time on linefeeds and
encodings.

If the files need different C<binmode> settings, for example if
comparing irrespective of the linefeeds involved, do not set this
option, and instead pass in the file handles with C<binmode> already set
as appropriate on those file handles.

=item I<fscheck>

If set and true, perform C<stat> tests on the input to check whether the
device and inode numbers are identical. If so, this will avoid the need
to check the file contents. This test may run afoul network filesystems
or other edge cases possibly mentioned in L<perlport>.

=item I<reason>

A scalar reference that will be populated with a reason the files
differ. Grep the source for what reasons are possible.

  my $msg = '';
  fcmp($f1, $f1, reason => \$msg);

I<reason> will only be changed if the files differ, so may contain a
stale value if the same scalar reference is used in multiple calls
to B<fcmp>.

=item I<RS>

Input Record Separator value for C<$/>, see the docs for such in
L<perlvar>. Binary file comparisons will likely benefit from the use
of a fixed record size, as who knows how long the "lines" could be in
such files.

=item I<sizecheck>

If set and false, disables the default C<-s> file size test on the input
files. This will force the file contents to be checked, even if the
files are of differing size (and thus stand a good chance of not being
identical). (Sparse files (untested) or unknown unknowns prompt the
inclusion of this knob.)

=item I<tells>

An array reference that will be populated with the C<tell> offsets of
where the files differ. Enabling this parameter disables the
I<sizecheck> option, thus forcing inspection of the file contents.

  my @where;
  fcmp($f1, $f1, tells => \@where);

Will only be set if the files differ or EOF is encountered (perhaps
check I<reason>) and nothing else goes awry.

=back

=head1 BUGS

No attempt at portability is made; in particular, this module assumes
Unix file system semantics for the C<fscheck> parameter.

Newer versions of this module may be available from CPAN. If the bug is
in the latest version, check:

L<http://github.com/thrig/File-Cmp>

=head1 HISTORY

As a historical note, there was an old L<File::Cmp> module from 1996-10-21
that exported C<cmp_file>. That old interface is not replicated in this
implementation, though would not be difficult to add, if necessary.

L<http://backpan.perl.org/authors/id/J/JN/JNH/>

=head1 SEE ALSO

L<cmp(1)>, L<perlfunc>, L<perlport>, L<perlvar>

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2015 by Jeremy Mates

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=cut
