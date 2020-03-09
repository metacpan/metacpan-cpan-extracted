# Copyright 2009, 2010, 2011, 2014 Kevin Ryde

# This file is part of I18N-Langinfo-Wide.
#
# I18N-Langinfo-Wide is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# I18N-Langinfo-Wide is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with I18N-Langinfo-Wide.  If not, see <http://www.gnu.org/licenses/>.

package I18N::Langinfo::Wide;
use 5.008001;
use strict;
use warnings;
use I18N::Langinfo ();

# version 2.25 for Encode::Alias recognise "646" on netbsd
use Encode 2.25;

our $VERSION = 9;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(langinfo to_wide);

# not yet ...
# %EXPORT_TAGS = (all => \@EXPORT_OK);


# As of I18N::Langinfo 0.02 in perl 5.10.1 all the langinfo()s are locale
# character strings.  The binary ones like GROUPING or P_CS_PRECEDES are not
# offered.  (glibc categories.def sets out which is what.)
#
# exists $_byte{$key_integer} means a byte string
our %_byte;
BEGIN {
  @_byte{ # hash slice
    grep {defined}
      map {eval "I18N::Langinfo::$_()"}
        qw(GROUPING
           MON_GROUPING
           FRAC_DIGITS
           INT_FRAC_DIGITS
           P_CS_PRECEDES
           P_SEP_BY_SPACE
           N_CS_PRECEDES
           N_SEP_BY_SPACE
           P_SIGN_POSN
           N_SIGN_POSN
           INT_P_CS_PRECEDES
           INT_P_SEP_BY_SPACE
           INT_N_CS_PRECEDES
           INT_N_SEP_BY_SPACE
           INT_P_SIGN_POSN
           INT_N_SIGN_POSN)
      } = ();
}

sub langinfo {
  my ($key) = @_;
  my $str = I18N::Langinfo::langinfo($key);
  if ($_byte{$key}) {
    return $str;
  } else {
    return to_wide($str);
  }
}

sub to_wide {
  my ($str) = @_;
  if (utf8::is_utf8($str)) { return $str; }

  # netbsd langinfo(CODESET) returns "646" meaning ISO-646, ie. ASCII.  Must
  # put that through resolve_alias() to turn it into "ascii".
  #
  return Encode::decode (Encode::resolve_alias
                         (I18N::Langinfo::langinfo
                          (I18N::Langinfo::CODESET())),
                         $str, Encode::FB_CROAK());
}

1;
__END__

=for stopwords POSIX charset Eg funcs latin-1 ebcdic I18N-Langinfo-Wide Ryde langinfo

=head1 NAME

I18N::Langinfo::Wide -- langinfo functions returning wide-char strings

=head1 SYNOPSIS

 use I18N::Langinfo 'ABMON_1';
 use I18N::Langinfo::Wide 'langinfo';
 print langinfo(ABMON_1),"\n";   # "January"

=head1 DESCRIPTION

This little module offers a C<langinfo()> which is as per L<I18N::Langinfo>
but returns wide-char strings rather than locale charset bytes.

C<I18N::Langinfo> uses C<nl_langinfo()> and so may be available only on
Unix/POSIX systems, depending how much the C library might emulate.

=head1 EXPORTS

Nothing is exported by default, but C<langinfo()> can be imported in usual
L<Exporter> style.  Eg.

    use I18N::Langinfo::Wide 'langinfo';

There's no C<:all> tag, as not sure if it'd be better to import just the new
funcs, or everything from C<I18N::Langinfo> too.

=head1 FUNCTIONS

=over 4

=item C<$str = I18N::Langinfo::Wide::langinfo ($what)>

Return a wide-char string of information for the given C<$what>.  C<$what> is
an integer, one of the constants from C<I18N::Langinfo> like C<ABDAY_1>.

    my $what = I18N::Langinfo::ABDAY_1();
    print I18N::Langinfo::Wide::langinfo($what);  # "Sunday"

As of C<I18N::Langinfo> 0.02 (Perl 5.10.1), all the return values are
character strings.  The underlying C<nl_langinfo()> function has some byte
returns like C<GROUPING>, but they're not available through the Perl
interface.  The intention would be that C<I18N::Langinfo::Wide> would leave
the byte ones as bytes.

=item C<$str = I18N::Langinfo::Wide::to_wide ($str)>

Return C<$str> converted to a wide-char string.  If C<$str> is a byte string
then it's assumed be in the current locale charset per C<langinfo(CODESET)>.
If C<$str> is already wide chars then it's returned unchanged.

=back

=head1 BUGS

In the GNU C Library 2.10.1 through 2.17, C<langinfo()> on C<ALT_DIGITS> or
C<ERA> returns only the first digit or first era.  This is a bug in the C
library which neither C<I18N::Langinfo> nor C<I18N::Langinfo::Wide> attempt
to address.  (C<nl_langinfo()> returns nulls C<\0> between the characters or
eras, but the POSIX spec calls for semicolons:
L<http://www.opengroup.org/onlinepubs/009695399/basedefs/xbd_chap07.html>.)

=head1 SEE ALSO

L<I18N::Langinfo>, L<POSIX::Wide>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/i18n-langinfo-wide/index.html>

=head1 LICENSE

I18N-Langinfo-Wide is Copyright 2008, 2009, 2010, 2011, 2014 Kevin Ryde

I18N-Langinfo-Wide is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

I18N-Langinfo-Wide is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
I18N-Langinfo-Wide.  If not, see L<http://www.gnu.org/licenses/>.

=cut
