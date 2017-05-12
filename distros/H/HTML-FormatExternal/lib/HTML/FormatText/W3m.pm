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

package HTML::FormatText::W3m;
use 5.006;
use strict;
use warnings;
use URI::file;
use HTML::FormatExternal;
our @ISA = ('HTML::FormatExternal');

our $VERSION = 26;

use constant DEFAULT_LEFTMARGIN => 0;
use constant DEFAULT_RIGHTMARGIN => 80;

sub program_full_version {
  my ($self_or_class) = @_;
  return $self_or_class->_run_version (['w3m', '-version']);
}
sub program_version {
  my ($self_or_class) = @_;
  my $version = $self_or_class->program_full_version;
  if (! defined $version) { return undef; }

  # eg. "w3m version w3m/0.5.2, options lang=en,m17n,image,color,..."
  $version =~ m{^w3m version (?:w3m/)?(.*?),}i
    or $version =~ /^(.*)/;  # whole first line if format not recognised
  return $1 . substr($version,0,0);  # retain taintedness
}

sub _make_run {
  my ($class, $input_filename, $options) = @_;
  my @command = ('w3m', '-dump', '-T', 'text/html');

  # w3m seems to use one less than the given -cols, presumably designed with
  # a tty in mind so "-cols 80" prints just 79 so as not to wrap around
  if (defined $options->{'_width'}) {
    push @command, '-cols', $options->{'_width'} + 1;
  }

  if ($options->{'input_charset'}) {
    push @command, '-I', $options->{'input_charset'};
  }
  if ($options->{'output_charset'}) {
    push @command, '-O', $options->{'output_charset'};
  }

  # 'w3m_options' not documented ...
  push @command, @{$options->{'w3m_options'} || []};

  # w3m (circa its version 0.5.3) interprets "%" in the input
  # filename as URI style %ff hex encodings.  Turn unusual filenames
  # like "%" into full file:// using URI::file.
  #
  # Filenames merely starting "-" can be given as "./-" etc to avoid
  # them being interpreted as options.  The file:// does this too.
  #
  push @command, URI::file->new_abs($input_filename)->as_string;

  return (\@command);
}

sub new {
  my ($class, %self) = @_;
  return bless \%self, $class;
}
sub format {
  my ($self, $html) = @_;
  if (ref $html) { $html = $html->as_HTML; }
  return $self->format_string ($html, %$self);
}

1;
__END__

=for stopwords HTML-FormatExternal formatters Ryde

=head1 NAME

HTML::FormatText::W3m - format HTML as plain text using w3m

=for test_synopsis my ($text, $filename, $html_string, $formatter, $tree)

=head1 SYNOPSIS

 use HTML::FormatText::W3m;
 $text = HTML::FormatText::W3m->format_file ($filename);
 $text = HTML::FormatText::W3m->format_string ($html_string);

 $formatter = HTML::FormatText::W3m->new (rightmargin => 60);
 $tree = HTML::TreeBuilder->new_from_file ($filename);
 $text = $formatter->format ($tree);

=head1 DESCRIPTION

C<HTML::FormatText::W3m> turns HTML into plain text using the C<w3m> program.

=over 4

L<http://sourceforge.net/projects/w3m>

=back

The module interface is compatible with formatters like C<HTML::FormatText>,
but all parsing etc is done by w3m.

See C<HTML::FormatExternal> for the formatting functions and options, all of
which are supported by C<HTML::FormatText::W3m>.

=head1 SEE ALSO

L<HTML::FormatExternal>, L<w3m(1)>

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
