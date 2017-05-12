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

package HTML::FormatText::Lynx;
use 5.006;
use strict;
use warnings;
use URI::file;
use HTML::FormatExternal;
our @ISA = ('HTML::FormatExternal');

our $VERSION = 26;

use constant DEFAULT_LEFTMARGIN => 2;
use constant DEFAULT_RIGHTMARGIN => 72;

# return true if the "-nomargins" option is available (new in Lynx
# 2.8.6dev.12 from June 2005)
use constant::defer _have_nomargins => sub {
  my ($class) = @_;
  my $help = $class->_run_version (['lynx', '-help']);
  return (defined $help && $help =~ /-nomargins/);
};

sub program_full_version {
  my ($self_or_class) = @_;
  return $self_or_class->_run_version (['lynx', '-version']);
}
sub program_version {
  my ($self_or_class) = @_;
  my $version = $self_or_class->program_full_version;
  if (! defined $version) { return undef; }

  # eg. "Lynx Version 2.8.7dev.10 (21 Sep 2008)"
  $version =~ /^Lynx Version (.*?) \(/i
    or $version =~ /^(.*)/;  # whole first line if format not recognised
  return $1 . substr($version,0,0);  # retain taintedness
}

sub _make_run {
  my ($class, $input_filename, $options) = @_;
  my @command = ('lynx', '-dump', '-force_html');

  if (defined $options->{'_width'}) {
    push @command, '-width', $options->{'_width'};
    if ($class->_have_nomargins) {
      push @command, '-nomargins';
    }
  }
  if (my $input_charset = $options->{'input_charset'}) {
    push @command, '-assume_charset', $input_charset;
  }
  if (my $output_charset = $options->{'output_charset'}) {
    push @command, '-display_charset', $output_charset;
  }
  if ($options->{'justify'}) {
    push @command, '-justify';
  }
  if ($options->{'unique_links'}) {
    push @command, '-unique_urls';
  }


  # -underscore gives _foo_ style for <u> underline, though it seems to need
  # -with_backspaces to come out.  It doesn't use backspaces it seems,
  # unlike the name would suggest ...

  # 'lynx_options' not documented ...
  push @command, @{$options->{'lynx_options'} || []};

  # "lynx -" means read standard input.
  # Any other "-foo" is an option.
  # Recent lynx has "--" to mean end of options, but not circa 2.8.6.
  # "lynx dir/http:" attempts to connect to something.
  # Escape all this by URI::file.
  push @command, URI::file->new_abs($input_filename)->as_string;

  return (\@command);
}

1;
__END__

=for stopwords HTML-FormatExternal formatters latin-1 iso-8859-1 boolean Ryde eg

=head1 NAME

HTML::FormatText::Lynx - format HTML as plain text using lynx

=for test_synopsis my ($text, $filename, $html_string, $formatter, $tree)

=head1 SYNOPSIS

 use HTML::FormatText::Lynx;
 $text = HTML::FormatText::Lynx->format_file ($filename);
 $text = HTML::FormatText::Lynx->format_string ($html_string);

 $formatter = HTML::FormatText::Lynx->new (rightmargin => 60);
 $tree = HTML::TreeBuilder->new_from_file ($filename);
 $text = $formatter->format ($tree);

=head1 DESCRIPTION

C<HTML::FormatText::Lynx> turns HTML into plain text using the C<lynx> program.

=over 4

L<http://lynx.isc.org/>

=back

The module interface is compatible with formatters like C<HTML::FormatText>,
but all parsing etc is done by lynx.

See C<HTML::FormatExternal> for the formatting functions and options, all of
which are supported by C<HTML::FormatText::Lynx>, with the following caveats

=over 4

=item C<leftmargin>, C<rightmargin>

Prior to the C<-nomargins> option of Lynx 2.8.6dev.12 (June 2005) an
additional 3 space margin is always applied within the requested left and
right positions.

=item C<input_charset>, C<output_charset>

Note that "latin-1" etc is not accepted, it must be "iso-8859-1" etc.

C<output_charset> becomes the C<-display_charset> option and can't be used
on very old C<lynx> which doesn't have that option (eg. lynx circa 2.8.1).
Perhaps in the future C<output_charset> could be dropped if it's already
what will be output, or throw a Perl error when unsupported.

=back

=head2 Extra Options

=over 4

=item C<justify> (boolean)

If true then C<-justify> is passed to lynx to have all lines in the paragraph
padded out with extra spaces to the given C<rightmargin> (or default right
margin).

=item C<unique_links> (boolean)

If true then C<-unique_urls> is passed to have lynx give its link footnotes
just once for each distinct URL, re-used when the same URL occurs more than
once in the document.  This module option is per
L<HTML::FormatText::WithLinks>.

=back

=head1 SEE ALSO

L<HTML::FormatExternal>, L<lynx(1)>

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
