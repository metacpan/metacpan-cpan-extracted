# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2015 Kevin Ryde

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



# Maybe:
#     capture error output
#     errors_to => \$var
#     combine error messages
#


package HTML::FormatExternal;
use 5.006;
use strict;
use warnings;
use Carp;
use File::Spec 0.80; # version 0.80 of perl 5.6.0 or thereabouts for devnull()
use IPC::Run;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 26;

sub new {
  my ($class, %self) = @_;
  return bless \%self, $class;
}
sub format {
  my ($self, $html) = @_;
  if (ref $html) { $html = $html->as_HTML; }
  return $self->format_string ($html, %$self);
}

use constant _WIDE_INPUT_CHARSET => 'UTF-8';
use constant _WIDE_OUTPUT_CHARSET => 'UTF-8';

# format_string() takes the easy approach of putting the string in a temp
# file and letting format_file() do the real work.  The formatter programs
# can generally read stdin and write stdout, so might do that with select()
# to simultaneously write and read back.
#
sub format_string {
  my ($class, $html_str, %options) = @_;

  my $fh = _tempfile();
  my $input_wide = eval { utf8::is_utf8($html_str) };
  _output_wide(\%options, $input_wide);

  # insert <base> while in wide chars
  if (defined $options{'base'}) {
    $html_str = _base_prefix(\%options, $html_str, $input_wide);
  }

  if ($input_wide) {
    if (! $options{'input_charset'}) {
      $options{'input_charset'} = $class->_WIDE_INPUT_CHARSET;
    }
    ### input_charset for wide: $options{'input_charset'}
    if ($options{'input_charset'} eq 'entitize') {
      $html_str = _entitize($html_str);
      delete $options{'input_charset'};
    } else {
      my $layer = ":encoding($options{'input_charset'})";
      binmode ($fh, $layer) or die 'Cannot add layer ',$layer;
    }
  }

  do {
    print $fh $html_str
      and close($fh)
    } || die 'Cannot write temp file: ',$!;

  return $class->format_file ($fh->filename, %options);
}

# Left margin is synthesized by adding spaces afterwards because the various
# programs have pretty variable support for a specified margin.
#   * w3m doesn't seem to have a left margin option at all
#   * lynx has one but it's too well hidden in its style sheet or something
#   * elinks has document.browse.margin_width but it's limited to 8 or so
#   * netrik doesn't seem to have one at all
#   * vilistextum has a "spaces" internally for lists etc but no apparent
#     way to initialize from the command line
#
sub format_file {
  my ($class, $filename, %options) = @_;

  # If neither leftmargin nor rightmargin are specified then '_width' is
  # unset and the _make_run() funcs leave it to the program defaults.
  #
  # If either leftmargin or rightmargin are set then '_width' is established
  # and the _make_run() funcs use it and and zero left margin, then the
  # actual left margin is applied below.
  #
  # The DEFAULT_LEFTMARGIN and DEFAULT_RIGHTMARGIN establish the defaults
  # when just one of the two is set.  Not good hard coding those values,
  # but the programs don't have anything to set one but not the other.
  #
  my $leftmargin  = $options{'leftmargin'};
  my $rightmargin = $options{'rightmargin'};
  if (defined $leftmargin || defined $rightmargin) {
    if (! defined $leftmargin)  { $leftmargin  = $class->DEFAULT_LEFTMARGIN; }
    if (! defined $rightmargin) { $rightmargin = $class->DEFAULT_RIGHTMARGIN; }
    $options{'_width'} = $rightmargin - $leftmargin;
  }

  _output_wide(\%options, 0);   # file input is reckoned as not wide
  if ($options{'output_wide'}) {
    $options{'output_charset'} ||= $class->_WIDE_OUTPUT_CHARSET;
  }

  my $tempfh;
  if (defined $options{'base'}) {
    # insert <base> by copying to a temp file

    # File::Copy rudely calls eq() to compare $from and $to.  Need either
    # File::Temp 0.18 to have that work on $tempfh, or File::Copy 2.??? for
    # it to check an overload method exists first.  Newer File::Temp is
    # available from cpan, where File::Copy may not be, so ask for
    # File::Temp 0.18.
    require File::Temp;
    File::Temp->VERSION(0.18);

    # must sysread()/syswrite() because that's what File::Copy does (as of
    # its version 2.30) so anything held in the perl buffering by the normal
    # read() is lost.

    my $initial;
    my $fh;
    do {
      open $fh, '<', $filename
        and binmode $fh
        and defined (sysread $fh, $initial, 4)
      } || croak "Cannot open $filename: $!";
    ### $initial

    $initial = _base_prefix(\%options, $initial, 0);

    $tempfh = _tempfile();
    $tempfh->autoflush(1);
    require File::Copy;
    do {
      defined(syswrite($tempfh, $initial))
        and File::Copy::copy($fh, $tempfh)
        and close $tempfh
        and close $fh
      } || croak "Cannot copy $filename to temp file: $!";


    $filename = $tempfh->filename;
  }

  # # dump the file being crunched
  # print "Bytes passed to program:\n";
  # IPC::Run::run(['hd'], '<',$filename, '|',['cat']);

  # _make_run() can set $options{'ENV'} too
  my ($command_aref, @run) = $class->_make_run($filename, \%options);
  my $env = $options{'ENV'} || {};

  ### $command_aref
  ### @run
  ### $env

  if (! @run) {
    push @run, '<', File::Spec->devnull;
  }

  my $str;
  {
    local %ENV = (%ENV, %$env); # overrides from _make_command()
    eval { IPC::Run::run($command_aref,
                         @run,
                         '>', \$str,
                         # FIXME: what to do with stderr ?
                         # '2>', File::Spec->devnull,
                        ) };
  }
  _die_on_insecure();
  ### $str

  ### final output_wide: $options{'output_wide'}
  if ($options{'output_wide'}) {
    require Encode;
    $str = Encode::decode ($options{'output_charset'}, $str);
  }

  if ($leftmargin) {
    my $fill = ' ' x $leftmargin;
    $str =~ s/^(.)/$fill$1/mg;  # non-empty lines only
  }
  return $str;
}

# most program running errors are quietly ignored for now, but re-throw
# "Insecure $ENV{PATH}" when cannot run due to taintedness.
sub _die_on_insecure {
  if ($@ =~ /^Insecure/) {
    die $@;
  }
}

sub _run_version {
  my ($self_or_class, $command_aref, @ipc_options) = @_;
  ### _run_version() ...
  ###  $command_aref
  ### @ipc_options

  if (! @ipc_options) {
    @ipc_options = ('2>', File::Spec->devnull);
  }

  my $version;  # left undef if any exec/slurp problem
  eval { IPC::Run::run($command_aref,
                       '<', File::Spec->devnull,
                       '>', \$version,
                       @ipc_options) };

  # strip blank lines at end of lynx, maybe others
  if (defined $version) { $version =~ s/\n+$/\n/s; }
  return $version;
}

# return a File::Temp filehandle object
sub _tempfile {
  require File::Temp;
  my $fh = File::Temp->new (TEMPLATE => 'HTML-FormatExternal-XXXXXX',
                            SUFFIX => '.html',
                            TMPDIR => 1);
  binmode($fh) or die 'Oops, cannot set binmode() on temp file';

  ### tempfile: $fh->filename
  #  $fh->unlink_on_destroy(0);  # to preserve for debugging ...

  return $fh;
}

sub _output_wide {
  my ($options, $input_wide) = @_;
  if (! defined $options->{'output_wide'}
      || $options->{'output_wide'} eq 'as_input') {
    $options->{'output_wide'} = $input_wide;
  }
}

# $str is HTML or some initial bytes.
# Return a new string with <base> at the start.
# 
sub _base_prefix {
  my ($options, $str, $input_wide) = @_;
  my $base = delete $options->{'base'};
  ### _base_prefix: $base

  $base = "$base";           # stringize possible URI object
  $base = _entitize($base);  # probably shouldn't be any non-ascii in a url
  $base = "<base href=\"$base\">\n";

  my $pos = 0;
  unless ($input_wide) {
    # encode $base in the input_charset, and possibly after a BOM.
    #
    # Lynx recognises a BOM, if it doesn't have other -assume_charset.  It
    # recognises it only at the start of the file, so must insert <base>
    # after it here to preserve that feature of Lynx.
    #
    # If input_charset is utf-32 or utf-16 then it seems reasonable to step
    # over any BOM.  But Lynx for some reason doesn't like a BOM together
    # with utf-32 or utf-16 specified.  Dunno if that's a bug or a feature
    # on its part.

    my $input_charset = $options->{'input_charset'};
    if (! defined $input_charset || lc($input_charset) eq 'utf-32') {
      if ($str =~ /^\000\000\376\377/) {
        $input_charset = 'utf-32be';
        $pos = 4;
      } elsif ($str =~ /^\377\376\000\000/) {
        $input_charset = 'utf-32le';
        $pos = 4;
      }
    }
    if (! defined $input_charset || lc($input_charset) eq 'utf-16') {
      if ($str =~ /^\376\377/) {
        $input_charset = 'utf-16be';
        $pos = 4;
      } elsif ($str =~ /^\377\376/) {
        $input_charset = 'utf-16le';
        $pos = 2;
      }
    }
    if (defined $input_charset) {
      # encode() errors out if unknown charset, and doesn't exist for older
      # Perl, in which case leave $base as ascii.  May not be right, but
      # ought to work with the various ASCII superset encodings.
      eval {
        require Encode;
        $base = Encode::encode ($input_charset, $base);
      };
    }
  }
  substr($str, $pos,0, $base);  # insert $base at $pos
  return $str;
}

# return $str with non-ascii replaced by &#123; entities
sub _entitize {
  my ($str) = @_;
  $str =~ s{([^\x20-\x7E])}{'&#'.ord($1).';'}eg;
  ### $str
  return $str;
}

1;
__END__

=for stopwords HTML-FormatExternal formatter formatters charset charsets TreeBuilder ie latin-1 config Elinks absolutized tty Ryde filename recognise BOM UTF entitized unrepresentable untaint superset onwards overstriking

=head1 NAME

HTML::FormatExternal - HTML to text formatting using external programs

=head1 DESCRIPTION

This is a collection of formatter modules which turn HTML into plain text by
dumping it through the respective external programs.

    HTML::FormatText::Elinks
    HTML::FormatText::Html2text
    HTML::FormatText::Links
    HTML::FormatText::Lynx
    HTML::FormatText::Netrik
    HTML::FormatText::Vilistextum
    HTML::FormatText::W3m
    HTML::FormatText::Zen

The module interfaces are compatible with C<HTML::Formatter> modules such as
C<HTML::FormatText>, but the external programs do all the work.

Common formatting options are used where possible, such as C<leftmargin> and
C<rightmargin>.  So just by switching the class you can use a different
program (or the plain C<HTML::FormatText>) according to personal preference,
or strengths and weaknesses, or what you've got.

There's nothing particularly difficult about piping through these programs,
but a unified interface hides details like how to set margins and how to
force input or output charsets.

=head1 FUNCTIONS

Each of the classes above provide the following functions.  The C<XXX> in
the class names here is a placeholder for any of C<Elinks>, C<Lynx>, etc as
above.

See F<examples/demo.pl> in the HTML-FormatExternal sources for a complete
sample program.

=head2 Formatter Compatible Functions

=over 4

=item C<< $text = HTML::FormatText::XXX->format_file ($filename, key=>value,...) >>

=item C<< $text = HTML::FormatText::XXX->format_string ($html_string, key=>value,...) >>

Run the formatter program over a file or string with the given options and
return the formatted result as a string.  See L</OPTIONS> below for possible
key/value options.  For example,

    $text = HTML::FormatText::Lynx->format_file ('/my/file.html');

    $text = HTML::FormatText::W3m->format_string
      ('<html><body> <p> Hello world! </p </body></html>');

C<format_file()> ensures any C<$filename> is interpreted as a filename (by
escaping as necessary against however the programs interpret command line
arguments).

=item C<< $formatter = HTML::FormatText::XXX->new (key=>value, ...) >>

Create a formatter object with the given options.  In the current
implementation an object doesn't do much more than remember the options for
future use.

    $formatter = HTML::FormatText::Elinks->new(rightmargin => 60);

=item C<< $text = $formatter->format ($tree_or_string) >>

Run the C<$formatter> program on a C<HTML::TreeBuilder> tree or a string,
using the options in C<$formatter>, and return the result as a string.

A TreeBuilder argument (ie. a C<HTML::Element>) is accepted for
compatibility with C<HTML::Formatter>.  The tree is simply turned into a
string with C<< $tree->as_HTML >> to pass to the program, so if you've got a
string already then give that instead of a tree.

C<HTML::Element> itself has a C<format()> method (see
L<HTML::Element/format>) which runs a given C<$formatter>.
A C<HTML::FormatExternal> object can be used for C<$formatter>.

    $text = $tree->format($formatter);

    # which dispatches to
    $text = $formatter->format($tree);

=back

=head2 Extra Functions

The following are extra methods not available in the plain
C<HTML::FormatText>.

=over 4

=item C<< HTML::FormatText::XXX->program_version () >>

=item C<< HTML::FormatText::XXX->program_full_version () >>

=item C<< $formatter->program_version () >>

=item C<< $formatter->program_full_version () >>

Return the version number of the formatter program as reported by its
C<--version> or similar option.  If the formatter program is not available
then return C<undef>.

C<program_version()> is the bare version number, perhaps with "beta" or
similar indication.  C<program_full_version()> is the entire version output,
which may include build options, copyright notice, etc.

    $str = HTML::FormatText::Lynx->program_version();
    # eg. "2.8.7dev.10"

    $str = HTML::FormatText::W3m->program_full_version();
    # eg. "w3m version w3m/0.5.2, options lang=en,m17n,image,..."

The version number of the respective Perl module itself is available in the
usual way (see L<UNIVERSAL/VERSION>).

    $modulever = HTML::FormatText::Netrik->VERSION;
    $modulever = $formatter->VERSION

=back

=head1 CHARSETS

File or byte string input is by default interpreted by the programs in their
usual ways.  This should mean HTML Latin-1 but user configurations might
override that and some programs recognise a C<< <meta> >> charset
declaration or a Unicode BOM.  The C<input_charset> option below can force
the input charset.

Perl wide-character input string is encoded and passed to the program in
whatever way it best understands.  Usually this is UTF-8 but in some cases
it is entitized instead.  The C<input_charset> option can force the input
charset to use if for some reason UTF-8 is not best.

The output string is either bytes or wide chars.  By default output is the
same as input, so wide char string input gives wide output and byte input
string or file input gives byte output.  The C<output_wide> option can force
the output type (and is the way to get wide chars back from
C<format_file()>).

Byte output is whatever the program produces.  Its default might be the
locale charset or other user configuration which suits direct display to the
user's terminal.  The C<output_charset> option can force the output to be
certain or to be ready for further processing.

Wide char output is done by choosing the best output charset the program can
do and decoding its output.  Usually this means UTF-8 but some of the
programs may only have less.  The C<output_charset> option can force the
charset used and decoded.  If it's something less than UTF-8 then some
programs might for example give ASCII art approximations of otherwise
unrepresentable characters.

Byte input is usual for HTML downloaded from a HTTP server or from a MIME
email and the headers have the C<input_charset> which applies.  Byte output
is good to go straight out to a tty or back to more MIME etc.  The input and
output charsets could differ if a server gives something other than what you
want for final output.

Wide chars are most convenient for crunching text within Perl.  The default
wide input giving wide output is designed to be transparent for this.

For reference, if a C<HTML::Element> tree contains wide char strings then
its usual C<as_HTML()> method, which is used by C<format()> above, produces
wide char HTML so the formatters here give wide char text.  Actually
C<as_HTML()> produces all ASCII because its default behaviour is to entitize
anything "unsafe", but it's still a wide char string so the formatted output
text is wide.

=head1 OPTIONS

The following options can be given to the constructor or to the formatting
methods.  The defaults are whatever the respective programs do.  The
programs generally read their config files when dumping so the defaults and
formatting details may follow the user's personal preferences.  Usually this
is a good thing.

=over 4

=item C<< leftmargin => INTEGER >>

=item C<< rightmargin => INTEGER >>

The column numbers for the left and right hand ends of the text.
C<leftmargin> 0 means no padding on the left.  C<rightmargin> is the text
width, so for instance 60 would mean the longest line is 60 characters
(inclusive of any C<leftmargin>).  These options are compatible with
C<HTML::FormatText>.

C<rightmargin> is not necessarily a hard limit.  Some of the programs will
exceed it in a HTML literal C<< <pre> >>, or a run of C<&nbsp;> or similar.

=item C<< input_charset => STRING >>

Force the HTML input to be interpreted as bytes of the given charset,
irrespective of locale, user configuration, C<< <meta> >> in the HTML, etc.

=item C<< output_charset => STRING >>

Force the text output to be encoded as the given charset.  The default
varies among the programs, but usually defaults to the locale.

=item C<< output_wide => 0,1,"as_input" >>

Select output string as wide characters rather than bytes.  The default is
C<"as_input"> which means a wide char input string results in a wide char
output string and a byte input or file input is byte output.  See
L</CHARSETS> above for how wide characters work.

Bytes or wide chars output can be forced by 0 or 1 respectively.  For
example to get wide char output when formatting a file,

    $wide_char_text = HTML::FormatText::W3m->format_file
                       ('/my/file.html', output_wide => 1);

=item C<< base => STRING >>

Set the base URL for any relative links within the HTML (similar to
C<HTML::FormatText::WithLinks>).  Usually this should be the location the
HTML was downloaded from.

If the document contains its own C<< <base> >> setting then currently the
document takes precedence.  Only Lynx and Elinks display absolutized link
targets and the option has no effect on the other programs.

=back

=head1 TAINT MODE

The formatter modules can be used under C<perl -T> taint mode.  They run
external programs so it's necessary to untaint C<$ENV{PATH}> in the usual
way per L<perlsec/Cleaning Up Your Path>.

The formatted text strings returned are always tainted, on the basis that
they use or include data from outside the Perl program.  The
C<program_version()> and C<program_full_version()> strings are tainted too.

=head1 BUGS

C<leftmargin> is implemented by adding spaces to the program output.  For
byte output it this is ASCII spaces and that will be badly wrong for unusual
output like UTF-16 which is not a byte superset of ASCII.  For wide char
output the margin is applied after decoding to wide chars so is correct.
It'd be better to ask the programs to do the margin but their options for
that are poor.

There's nothing done with errors or warning messages from the programs.
Generally they make a best effort on doubtful HTML, but fatal errors like
bad options or missing libraries ought to be somehow trapped.

=head1 OTHER POSSIBILITIES

C<elinks> (from Aug 2008 onwards) and C<netrik> can produce ANSI escapes for
colours, underline, etc, and C<html2text> and C<lynx> can produce tty style
backspace overstriking.  This might be good for text destined for a tty or
further crunching.  Perhaps an C<ansi> or C<tty> option could enable this,
where possible, but for now it's deliberately turned off in those programs
to keep the default as plain text.

=head1 SEE ALSO

L<HTML::FormatText::Elinks>,
L<HTML::FormatText::Html2text>,
L<HTML::FormatText::Links>,
L<HTML::FormatText::Netrik>,
L<HTML::FormatText::Lynx>,
L<HTML::FormatText::Vilistextum>,
L<HTML::FormatText::W3m>,
L<HTML::FormatText::Zen>

L<HTML::FormatText>,
L<HTML::FormatText::WithLinks>,
L<HTML::FormatText::WithLinks::AndTables>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/html-formatexternal/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2015 Kevin Ryde

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
