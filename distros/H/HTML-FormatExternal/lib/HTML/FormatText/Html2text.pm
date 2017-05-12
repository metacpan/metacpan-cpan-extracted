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

package HTML::FormatText::Html2text;
use 5.006;
use strict;
use warnings;
use HTML::FormatExternal;
our @ISA = ('HTML::FormatExternal');

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 26;

use constant DEFAULT_LEFTMARGIN => 0;
use constant DEFAULT_RIGHTMARGIN => 79;

my $have_ascii;
my $have_utf8;
use constant::defer _check_help => sub {  # run once only
  my ($class) = @_;
  my $help = $class->_run_version (['html2text', '-help']);
  $have_ascii = (defined $help && $help =~ /-ascii/);
  $have_utf8  = (defined $help && $help =~ /-utf8/);
  return undef;
};

# return true if the "-ascii" option is available (new in html2text
# version 1.3.2 from Jan 2004)
sub _have_ascii {
  my ($class) = @_;
  $class->_check_help();
  return $have_ascii;
}

# return true if the "-utf8" option is available (a Debian addition circa 2009)
sub _have_utf8 {
  my ($class) = @_;
  $class->_check_help();
  return $have_utf8;
}

# The Debian -utf8 option can give UTF-8 output.
# For input believe entitized is the only way to be confident of working
# with both original and Debian extended.
#
use constant _WIDE_INPUT_CHARSET => 'entitize';
sub _WIDE_OUTPUT_CHARSET {
  my ($class) = @_;
  return ($class->_have_utf8() ? 'UTF-8' : 'iso-8859-1');
}

sub program_full_version {
  my ($self_or_class) = @_;
  return $self_or_class->_run_version (['html2text','-version'], '2>&1');
}
sub program_version {
  my ($self_or_class) = @_;
  my $version = $self_or_class->program_full_version;
  if (! defined $version) { return undef; }

  # eg. "This is html2text, version 1.3.2a"
  $version =~ /^.*version (.*)/
    or $version =~ /^(.*)/;  # whole first line if format not recognised
  return $1 . substr($version,0,0);  # retain taintedness
}

sub _make_run {
  my ($class, $input_filename, $options) = @_;

  # -nobs means don't do underlining with "_ backspace X" sequences.
  # Backspaces are fun for teletype output, but the intention here is plain
  # text.  The Debian html2text has -nobs by default anyway.
  #
  my @command = ('html2text', '-nobs');

  if (defined $options->{'_width'}) {
    push @command, '-width', $options->{'_width'};
  }

  if ($class->_have_ascii) {
    if (my $output_charset = $options->{'output_charset'}) {
      $output_charset = lc($output_charset);
      if ($output_charset eq 'ascii' || $output_charset eq 'ansi_x3.4-1968') {
        push @command, '-ascii';
      }
    }
  }

  # 'html2text_options' not documented ...
  push @command, @{$options->{'html2text_options'} || []};

  # "html2text -" input filename "-" means read standard input.
  # Any other "-foo" starting with "-" is an option and there's no apparent
  # "--" to mark the end of options (as of its version 1.3.2a).
  #
  # Normally html2text takes URL style file: or http:, but the debian
  # version mangles it to a bare filename only.  This makes it hard to
  # escape a name suitably to get through both.  Instead use standard input
  # which both versions read by default.

  return (\@command,
          '<', $input_filename);
}

1;
__END__

=for stopwords HTML-FormatExternal html2text formatters ascii charset latin-1 Ryde recognised entitized UTF

=head1 NAME

HTML::FormatText::Html2text - format HTML as plain text using html2text

=for test_synopsis my ($text, $filename, $html_string, $formatter, $tree)

=head1 SYNOPSIS

 use HTML::FormatText::Html2text;
 $text = HTML::FormatText::Html2text->format_file ($filename);
 $text = HTML::FormatText::Html2text->format_string ($html_string);

 $formatter = HTML::FormatText::Html2text->new;
 $tree = HTML::TreeBuilder->new_from_file ($filename);
 $text = $formatter->format ($tree);

=head1 DESCRIPTION

C<HTML::FormatText::Html2text> turns HTML into plain text using the
C<html2text> program.

=over 4

L<http://www.mbayer.de/html2text/>

=back

The module interface is compatible with formatters like C<HTML::FormatText>,
but all parsing etc is done by html2text.

See C<HTML::FormatExternal> for the formatting functions and options, with
the following caveats,

=over 4

=item C<input_charset>

Currently this option has no effect.  Input generally has to be latin-1
only, though the Debian extended C<html2ext> interprets a C<< <meta> >>
charset directive in the HTML header.

Various C<&> style named or numbered entities are recognised and result in
suitable output.  The suggestion would be entitized input for maximum
portability among C<html2text> versions.

=item C<output_charset>

If set to "ascii" or "ANSI_X3.4-1968" (both case-insensitive) the
C<html2text -ascii> option is used, when available (C<html2text> 1.3.2 from
Jan 2004).

If set to "UTF-8" then Debian extension C<-utf8> option is used (circa
2009).

Apart from this there's no control over the output charset.

=back

=head1 SEE ALSO

L<HTML::FormatExternal>, L<html2text(1)>

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
