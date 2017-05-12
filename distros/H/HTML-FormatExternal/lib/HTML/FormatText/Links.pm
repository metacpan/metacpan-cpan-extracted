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

package HTML::FormatText::Links;
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
use constant _WIDE_INPUT_CHARSET => 'entitize';
use constant _WIDE_OUTPUT_CHARSET => 'iso-8859-1';

# It seems maybe some people make "links" an alias for "elinks", and the
# latter doesn't have -html-margin.  Maybe it'd be worth adapting to use
# elinks style "set document.browse.margin_width=0" in that case, but for
# now just don't use it if it doesn't work.
#
use constant::defer _have_html_margin => sub {
  my ($class) = @_;
  my $help = $class->_run_version (['links', '-help']);
  return (defined $help && $help =~ /-html-margin/);
};

sub program_full_version {
  my ($self_or_class) = @_;
  return $self_or_class->_run_version (['links', '-version']);
}
sub program_version {
  my ($self_or_class) = @_;
  my $version = $self_or_class->program_full_version;
  if (! defined $version) { return undef; }

  # first line like "Links 1.00pre12" or "Links 2.2"
  $version =~ /^Links (.*)/i
    or $version =~ /^(.*)/;  # whole first line if format not recognised
  return $1 . substr($version,0,0);  # retain taintedness
}

sub _make_run {
  my ($class, $input_filename, $options) = @_;
  my @command = ('links', '-dump', '-force-html');

  if (defined $options->{'_width'}) {
    push @command, '-width', $options->{'_width'};
    if ($class->_have_html_margin) {
      push @command, '-html-margin', 0;
    }
  }

  if (my $input_charset = $options->{'input_charset'}) {
    push @command,
      '-html-assume-codepage', _links_mung_charset ($input_charset),
        '-html-hard-assume', 1;
  }
  if (my $output_charset = $options->{'output_charset'}) {
    push @command, '-codepage', _links_mung_charset ($output_charset);
  }

  # 'links_options' not documented ...
  push @command, @{$options->{'links_options'} || []};

  # links interprets "%" in the input filename as URI style %ff hex
  # encodings.  Turn unusual filenames like "%" or "-" into full
  # file:// using URI::file.
  push @command, URI::file->new_abs($input_filename)->as_string;

  return (\@command);
}

# links (version 2.2 at least) accepts "latin1" but not "latin-1".  The
# latter is accepted by the other FormatExternal programs, so turn "latin-1"
# into "latin1" for convenience.
#
sub _links_mung_charset {
  my ($charset) = @_;
  $charset =~ s/^(latin)-([0-9]+)$/$1$2/i;
  return $charset;
}


1;
__END__

=for stopwords HTML-FormatExternal formatters charset UTF-8 unicode latin-1 latin1 Ryde

=head1 NAME

HTML::FormatText::Links - format HTML as plain text using links

=for test_synopsis my ($text, $filename, $html_string, $formatter, $tree)

=head1 SYNOPSIS

 use HTML::FormatText::Links;
 $text = HTML::FormatText::Links->format_file ($filename);
 $text = HTML::FormatText::Links->format_string ($html_string);

 $formatter = HTML::FormatText::Links->new (rightmargin => 60);
 $tree = HTML::TreeBuilder->new_from_file ($filename);
 $text = $formatter->format ($tree);

=head1 DESCRIPTION

C<HTML::FormatText::Links> turns HTML into plain text using the C<links>
program.

=over 4

L<http://links.twibright.com/>

=back

The module interface is compatible with formatters like C<HTML::FormatText>,
but all parsing etc is done by links.  See C<HTML::FormatExternal> for the
formatting functions and options, all of which are supported by
C<HTML::FormatText::Links>, with the following caveats.

=over 4

=item C<leftmargin>, C<rightmargin>

In past versions of links without the C<-html-margin> option you always get
an extra 3 spaces within the requested left and right margins.

=item C<input_charset>, C<output_charset>

An output charset requires Links 2.0 or higher (or some such version), and
as of 2.2 the output cannot be UTF-8 (though the input can be).  Various
unicode inputs are turned into reasonable output though, for example smiley
face U+263A becomes ":-)".

=back

Links can be a bit picky about its charset names.  This module attempts to
ease that by for instance turning "latin-1" (not accepted) into "latin1"
(which is accepted).  A full "ISO-8859-1" etc is accepted too.

=head1 SEE ALSO

L<HTML::FormatExternal>, L<links(1)>

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
