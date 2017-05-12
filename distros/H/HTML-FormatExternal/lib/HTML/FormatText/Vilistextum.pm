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


# The long options like --version depend on vilistextum being built with
# <getopt.h> and getopt_long().  The single-letter options like -v are
# always available.


package HTML::FormatText::Vilistextum;
use 5.006;
use strict;
use warnings;
use Carp;
use HTML::FormatExternal;
our @ISA = ('HTML::FormatExternal');

# uncomment this to run the ### lines
# use Smart::Comments;


our $VERSION = 26;

# no left margin by default, no option to add it
use constant DEFAULT_LEFTMARGIN => 0;
use constant DEFAULT_RIGHTMARGIN => 76; # file text.c has breite=76

# return true if vilistextum has its -u "--output-utf-8" option
use constant::defer _have_output_utf8 => sub {
  my ($class) = @_;
  my $help = $class->_run_version (['vilistextum', '-help']);
  return (defined $help && $help =~ /\s-u[, ]/);
};

use constant _WIDE_INPUT_CHARSET => 'entitize';
sub _WIDE_OUTPUT_CHARSET {
  my ($class) = @_;
  return ($class->_have_output_utf8() ? 'UTF-8' : 'iso-8859-1');
}

sub program_full_version {
  my ($self_or_class) = @_;
  return $self_or_class->_run_version (['vilistextum', '-v']);
}
sub program_version {
  my ($self_or_class) = @_;
  my $version = $self_or_class->program_full_version;
  if (! defined $version) { return undef; }

  # eg. "Vilistextum 2.6.9 (22.10.2006)"
  $version =~ m{^Vilistextum ([0-9][^ ]*)}i
    or $version =~ /^(.*)/;  # whole first line if format not recognised
  return $1;
}

sub _make_run {
  my ($self, $input_filename, $options) = @_;
  my @command = ('vilistextum');

  if (defined $options->{'_width'}) {
    push @command, '-w', $options->{'_width'};
  }

  if ($options->{'output_charset'}) {
    if (lc($options->{'output_charset'}) eq 'utf-8') {
      # If asked for utf-8 and no multibyte then don't want to silently give
      # back latin-1 instead.
      # Maybe it'd be better to use Encode.pm to convert.
      if (! $self->_have_output_utf8()) {
        croak "Output charset $options->{'output_charset'} not available, vilistextum built without multibyte";
      }
      push @command, '-u';

    } else {
      # Not sure about croaking on unknown charset.
      # if $output_charset ne 'latin-1' 'iso-8859-1'
      # croak "Output charset $options->{'output_charset'} unknown";
    }
  }

  # 'vilistextum_options' not documented ...
  push @command, @{$options->{'vilistextum_options'} || []};

  # "-" means to stdout
  push @command, $input_filename, '-';

  return (\@command);
}

1;
__END__

=for stopwords HTML-FormatExternal vilistextum sourceforge.net formatters charset Ryde UTF

=head1 NAME

HTML::FormatText::Vilistextum - format HTML as plain text using vilistextum

=for test_synopsis my ($text, $filename, $html_string, $formatter, $tree)

=head1 SYNOPSIS

 use HTML::FormatText::Vilistextum;
 $text = HTML::FormatText::Vilistextum->format_file ($filename);
 $text = HTML::FormatText::Vilistextum->format_string ($html_string);

 $formatter = HTML::FormatText::Vilistextum->new;
 $tree = HTML::TreeBuilder->new_from_file ($filename);
 $text = $formatter->format ($tree);

=head1 DESCRIPTION

C<HTML::FormatText::Vilistextum> turns HTML into plain text using the
C<vilistextum> program.

=over 4

L<http://bhaak.net/vilistextum/>

=back

The module interface is compatible with formatters like C<HTML::FormatText>,
but all parsing etc is done by vilistextum.

See C<HTML::FormatExternal> for the formatting functions and options, with
the following caveats,

=over 4

=item C<input_charset>

There's no C<input_charset> option yet.  (C<vilistextum> has a C<-y> option
but it might be only a default, with the document C<< <meta> >> taking
precedence, whereas the intention of C<input_charset> is to override the
document.)

=item C<output_charset>

Charset "UTF-8" can be given for UTF-8 output.  This passes C<-u> to
C<vilistextum>, which is only available if built with C<--enable-multibyte>
(as of its version 2.6.9).

=back

=head1 SEE ALSO

L<HTML::FormatExternal>, L<vilistextum(1)>

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
