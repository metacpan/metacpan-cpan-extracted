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

package HTML::FormatText::Zen;
use 5.006;
use strict;
use warnings;
use HTML::FormatExternal;
our @ISA = ('HTML::FormatExternal');

our $VERSION = 26;

use constant DEFAULT_LEFTMARGIN => 0;
use constant DEFAULT_RIGHTMARGIN => 80;

# no input charset options
use constant _WIDE_INPUT_CHARSET => 'entitize';

sub program_full_version {
  my ($self_or_class) = @_;
  return $self_or_class->_run_version (['zen', '--version']);
}
sub program_version {
  my ($self_or_class) = @_;
  my $version = $self_or_class->program_full_version;
  if (! defined $version) { return undef; }

  # eg. "zen version 0.2.3"
  $version =~ /^zen version (.*)/i
    or $version =~ /^(.*)/;  # whole first line if format not recognised
  return $1 . substr($version,0,0);  # retain taintedness
}

sub _make_run {
  my ($class, $input_filename, $options) = @_;

  # Is it worth enforcing/checking this ?
  # Could use Encode.pm to convert the output without too much trouble.
  #
  #   if (my $input_charset = $options->{'input_charset'}) {
  #     $input_charset =~ /^latin-?1$|^iso-?8859-1$/i
  #       or croak "Zen only accepts latin-1 input";
  #   }
  #   if (my $output_charset = $options->{'output_charset'}) {
  #     $output_charset =~ /^latin-?1$|^iso-?8859-1$/i
  #       or croak "Zen only produces latin-1 output";
  #   }

  # 'zen_options' not documented ...
  return ([ 'zen', '-i', 'dump',
            @{$options->{'zen_options'} || []},
            '--',  # end of options
            $input_filename,
          ]);
}

1;
__END__

=for stopwords HTML-FormatExternal formatters charset latin-1 Ryde

=head1 NAME

HTML::FormatText::Zen - format HTML as plain text using zen

=for test_synopsis my ($text, $filename, $html_string, $formatter, $tree)

=head1 SYNOPSIS

 use HTML::FormatText::Zen;
 $text = HTML::FormatText::Zen->format_file ($filename);
 $text = HTML::FormatText::Zen->format_string ($html_string);

 $formatter = HTML::FormatText::Zen->new;
 $tree = HTML::TreeBuilder->new_from_file ($filename);
 $text = $formatter->format ($tree);

=head1 DESCRIPTION

C<HTML::FormatText::Zen> turns HTML into plain text using the C<zen>
program.

=over 4

L<http://www.nocrew.org/software/zen/>

=back

The module interface is compatible with formatters like C<HTML::FormatText>,
but all parsing etc is done by zen.

See C<HTML::FormatExternal> for the formatting functions.  The margins
options work but nothing else.

=over

=item C<rightmargin>

As of zen version 0.2.3 there is no right margin option.

=item C<input_charset>, C<output_charset>

As of zen version 0.2.3 the input charset is always latin-1 and output is
always latin-1.  Entities in the input seem to be truncated to 8-bits for
the output.

=back

=head1 SEE ALSO

L<HTML::FormatExternal>, L<zen(1)>

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
