# Copyright 2008, 2009, 2010, 2013, 2015 Kevin Ryde

# HTML-FormatExternal is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# HTML-FormatExternal is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with HTML-FormatExternal.  If not, see <http://www.gnu.org/licenses/>.

package HTML::FormatText::Netrik;
use 5.006;
use strict;
use warnings;
use URI::file;
use HTML::FormatExternal;
our @ISA = ('HTML::FormatExternal');

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 26;

use constant DEFAULT_LEFTMARGIN => 3;
use constant DEFAULT_RIGHTMARGIN => 77;

# as of Netrik 1.16.1 there's no input charsets, so entitize
use constant _WIDE_INPUT_CHARSET => 'entitize';

# --dump here as otherwise netrik runs the curses interface on the initial
# page given in ~/.netrikrc.  If there's no such file then it prints a
# little "usage: netrik html-file" but there's nothing interesting in that.
# Option '-' to read stdin which _run_version() makes /dev/null.
#
# --bw avoids warnings on a monochrome terminal.  Don't want colours for any
# usage message etc anyway.
#
sub program_full_version {
  my ($self_or_class) = @_;
  return $self_or_class->_run_version (['netrik','--bw','--version','--dump','-'], '2>&1');
}
sub program_version {
  my ($self_or_class) = @_;
  my $version = $self_or_class->program_full_version;
  if (! defined $version) { return undef; }

  # as of netrik 1.16.1 there doesn't seem to be any option that prints the
  # version number, it's possible it's not compiled into the binary at all
  return '(not reported)';
}

sub _make_run {
  my ($class, $input_filename, $options) = @_;
  ### Netrik _make_run() ...

  #   if (! $options->{'ansi_colour'}) {
  #     push @command, '--bw';
  #   }

  # COLUMNS influences the curses tigetnum("cols") used under --term-width.
  # Slightly hairy, but it has the right effect.
  if (defined $options->{'_width'}) {
    $options->{'ENV'}->{'COLUMNS'} = $options->{'_width'};
  }

  # netrik 1.16.1 does a curses setupterm() even for a --dump so it must
  # have a TERM.  Think "TERM=dumb" is known to any termcap or terminfo.
  # But leave a user's existing TERM setting alone in case it does something
  # good for netrik, though you'd hope it wouldn't affect --dump.
  #
  unless ($ENV{'TERM'}) {
    $options->{'ENV'}->{'TERM'} = 'dumb';
  }

  # --bw to avoid warnings when on a monochrome terminal.  Don't want
  # colours in a dump anyway.  (Option --bw is in options.txt and the
  # README.)
  #
  # 'netrik_options' not documented ...
  return ([ 'netrik', '--dump', '--bw',
            @{$options->{'netrik_options'} || []},

            # netrik interprets "%" in the input filename as URI style %ff hex
            # encodings.  And it rejects filenames with non-URI chars such as
            # "-" (except for "-" alone which means stdin).  Turn unusual
            # filenames like "%" or "-" into full file:// using URI::file.
            URI::file->new_abs($input_filename)->as_string,
          ]);
}

1;
__END__

=for stopwords HTML-FormatExternal netrik sourceforge.net formatters charset Ryde

=head1 NAME

HTML::FormatText::Netrik - format HTML as plain text using netrik

=for test_synopsis my ($text, $filename, $html_string, $formatter, $tree)

=head1 SYNOPSIS

 use HTML::FormatText::Netrik;
 $text = HTML::FormatText::Netrik->format_file ($filename);
 $text = HTML::FormatText::Netrik->format_string ($html_string);

 $formatter = HTML::FormatText::Netrik->new;
 $tree = HTML::TreeBuilder->new_from_file ($filename);
 $text = $formatter->format ($tree);

=head1 DESCRIPTION

C<HTML::FormatText::Netrik> turns HTML into plain text using the C<netrik>
program.

=over 4

L<http://netrik.sourceforge.net/>

=back

The module interface is compatible with formatters like C<HTML::FormatText>,
but all parsing etc is done by netrik.

C<netrik> normally emits colour escape sequences but that is disabled here
(its C<--bw> option) to get plain text.

See C<HTML::FormatExternal> for the formatting functions and options, with
the following caveats,

=over 4

=item C<input_charset>, C<output_charset>

These charset overrides have no effect.  Input might be single-byte only,
and output probably follows the input (as of netrik 1.15.7).

=back

=head1 BUGS

C<netrik> version 1.16.1 initializes curses even when doing just a
C<--dump>, so if you have a C<TERM> environment variable then it must be a
terminal type known to curses (L<terminfo(5)>).  If you have no C<TERM>
setting then C<HTML::FormatText::Netrik> runs C<netrik> with C<TERM=dumb> so
the code here works in a bare environment.  (But no attempt is made here to
validate or correct an existing C<TERM> value.)

=cut

# If you set something then it should be a known terminal type.  (C<netrik>
# uses the terminal type for colour escapes, which are disabled here, and as
# a final default text width if neither C<COLUMNS> nor
# C<ioctl(TIOCGWINSZ)>).

=pod

=head1 SEE ALSO

L<HTML::FormatExternal>, L<netrik(1)>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/html-formatexternal/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010, 2013, 2015 Kevin Ryde

HTML-FormatExternal is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

HTML-FormatExternal is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
HTML-FormatExternal.  If not, see L<http://www.gnu.org/licenses/>.

=cut
