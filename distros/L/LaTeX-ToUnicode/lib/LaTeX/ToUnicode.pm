use strict;
use warnings;
package LaTeX::ToUnicode;
BEGIN {
  $LaTeX::ToUnicode::VERSION = '0.54';
}
#ABSTRACT: Convert LaTeX commands to Unicode (simplistically)

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( convert debuglevel $endcw );

use utf8;
use Encode;
use LaTeX::ToUnicode::Tables;

# Terminating a control word (not symbol) the way TeX does: at the
# boundary between a letter (lookbehind) and a nonletter (lookahead),
# and then ignore any following whitespace.
our $endcw = qr/(?<=[a-zA-Z])(?=[^a-zA-Z]|$)\s*/;

# all we need for is debugging being on and off. And it's pretty random
# what gets output.
my $debug = 0;

sub debuglevel { $debug = shift; }
sub _debug {
  return unless $debug;
  # The backtrace info is split between caller(0) and caller(1), sigh.
  # We don't need the package name, it's included in $subr in practice.
  my (undef,$filename,$line,undef) = caller(0);
  my (undef,undef,undef,$subr) = caller(1);
  warn @_, " at $filename:$line ($subr)\n";
}

# The main conversion function.
# 
sub convert {
    my ($string, %options) = @_;
    #warn debug_hash_as_string("starting with: $string", %options);

    # First, remove leading and trailing horizontal whitespace
    # on each line of the possibly-multiline string we're given.
    $string =~ s/^[ \t]*//m;
    $string =~ s/[ \t]*$//m;
    
    # For HTML output, must convert special characters that were in the
    # TeX text (&<>) to their entities to avoid misparsing. We want to
    # do this first, because conversion of the markup commands might
    # output HTML tags like <tt>, and we don't want to convert those <>.
    # Although &lt;tt&gt; works, better to keep the output HTML as
    # human-readable as we can.
    # 
    if ($options{html}) {
        $string =~ s/([^\\]|^)&/$1&amp;/g;
        $string =~ s/</&lt;/g;
        $string =~ s/>/&gt;/g;
    }
    
    my $user_hook = $options{hook};
    if ($user_hook) {
        $string = &$user_hook($string, \%options);
        _debug("after user hook: $string");
    }
    
    # Convert general commands that take arguments, since (1) they might
    # insert TeX commands that need to be converted, and (2) because
    # their arguments could well contain constructs that will map to a
    # Perl string \x{nnnn} for Unicode character nnnn; those Perl braces
    # for the \x will confuse further parsing of the TeX.
    # 
    $string = _convert_commands_with_arg($string);
    _debug("after commands with arg: $string");
    
    # Convert markups (\texttt, etc.); they have the same brace-parsing issue.
    $string = _convert_markups($string, \%options);
    _debug("after markups: $string");
    
    # And urls, a special case of commands with arguments.
    $string = _convert_urls($string, \%options);
    _debug("after urls: $string");

    $string = _convert_control_words($string);
    _debug("after control words: $string");

    $string = _convert_control_symbols($string);
    _debug("after control symbols: $string");

    $string = _convert_accents($string);
    $string = _convert_german($string) if $options{german};
    $string = _convert_symbols($string);
    $string = _convert_ligatures($string);
    
    # Let's handle ties here, after all the other conversions, since
    # they don't fit well with any of the tables.
    # 
    # /~, or ~ at the beginning of a line, is probably part of a url or
    # path, not a tie. Otherwise, consider it a space, since a no-break
    # spot in TeX is most likely fine to break in text or HTML.
    # 
    $string =~ s,([^/])~,$1 ,g;
    
    # Remove kerns. Clearly needs generalizing/sharpening to recognize
    # dimens better, and plenty of other commands could use it.
    #_debug("before kern: $string");
    my $dimen_re = qr/[-+]?[0-9., ]+[a-z][a-z]\s*/;
    $string =~ s!\\kern${endcw}${dimen_re}!!g;
    
    # What the heck, let's do \hfuzz and \vfuzz too. They come up pretty
    # often and practically the same thing (plus ignore optional =)..
    $string =~ s!\\[hv]fuzz${endcw}=?\s*${dimen_re}!!g;    

    # After all the conversions, $string contains \x{....} constructs
    # (Perl Unicode characters) where translations have happened. Change
    # those to the desired output format. Thus we assume that the
    # Unicode \x{....}'s are not themselves involved in further
    # translations, which is, so far, true.
    # 
    if (! $options{entities}) {
      # Convert our \x strings from Tables.pm to the binary characters.
      
      # As an extra-special case, we want to preserve the translation of
      # \{ and \} as 007[bd] entities even if the --entities option is
      # not give; otherwise they'd get eliminated like all other braces.
      # Use a temporary cs \xx to keep them marked, and don't use braces
      # to delimit the argument since they'll get deleted.
      $string =~ s/\\x\{(007[bd])\}/\\xx($1)/g;
      
      # Convert all other characters to characters.
      # Assume exactly four hex digits, since we wrote Tables.pm that way.
      $string =~ s/\\x\{(....)\}/ pack('U*', hex($1))/eg;

    } elsif ($options{entities}) {
      # Convert the XML special characters that appeared in the input,
      # e.g., from a TeX \&. Unless we're generating HTML output, in
      # which case they have already been converted.
      if (! $options{html}) {
          $string =~ s/&/&amp;/g;
          $string =~ s/</&lt;/g;
          $string =~ s/>/&gt;/g;
      }
      
      # Our values in Tables.pm are simple ASCII strings \x{....},
      # so we can replace them with hex entities with no trouble.
      # Fortunately TeX does not have a standard \x control sequence.
      $string =~ s/\\x\{(....)\}/&#x$1;/g;
      
      # The rest of the job is about binary Unicode characters in the
      # input. We want to transform them into entities also. As always
      # in Perl, there's more than one way to do it, and several are
      # described here, just for the fun of it.
      my $ret = "";
      #
      # decode_utf8 is described in https://perldoc.perl.org/Encode.
      # Without the decode_utf8, all of these methods output each byte
      # separately; apparently $string is a byte string at this point,
      # not a Unicode string. I don't know why that is.
      $ret = decode_utf8($string);
      #
      # Transform everything that's not printable ASCII or newline into
      # entities.
      $ret =~ s/([^ -~\n])/ sprintf("&#x%04x;", ord($1)) /eg;
      # 
      # This method leaves control characters as literal; doesn't matter
      # for XML output, since control characters aren't allowed, but
      # let's use the regexp method anyway.
      #$ret = encode("ascii", decode_utf8($string), Encode::FB_XMLCREF);
      # 
      # The nice_string function from perluniintro also works.
      # 
      # This fails, just outputs numbers (that is, ord values):
      # foreach my $c (unpack("U*", $ret)) {
      # 
      # Without the decode_utf8, outputs each byte separately.
      # With the decode_utf8, works, but the above seems cleaner.
      #foreach my $c (split(//, $ret)) {
      #  if (ord($c) <= 31 || ord($c) >= 128) {
      #    $ret .= sprintf("&#x%04x;", ord($c));
      #  } else {
      #    $ret .= $c;
      #  }
      #}
      #
      $string = $ret; # assigned from above.
    }

    if ($string =~ /\\x\{/) {
      warn "LaTeX::ToUnicode::convert: untranslated \\x remains: $string\n";
      warn "LaTeX::ToUnicode::convert:   please report as bug.\n";
    }
    
    # Drop all remaining braces.
    $string =~ s/[{}]//g;
    
    if (! $options{entities}) {
      # With all the other braces gone, now we can convert the preserved
      # brace entities from \{ and \} to actual braces.
      $string =~ s/\\xx\((007[bd])\)/ pack('U*', hex($1))/eg;
    }

    # Backslashes might remain. Don't remove them, as it makes for a
    # useful way to find unhandled commands.

    # leave newlines alone, but trim spaces and tabs.
    $string =~ s/^[ \t]+//s;  # remove leading whitespace
    $string =~ s/[ \t]+$//s;  # remove trailing whitespace
    $string =~ s/[ \t]+/ /gs; # collapse all remaining whitespace to one space
    
    $string;
}

#  Convert commands that take a single braced argument. The table
# defines text we're supposed to insert before and after the argument.
# We let future processing handle conversion of both the inserted text
# and the argument.
# 
sub _convert_commands_with_arg {
    my $string = shift;

    foreach my $cmd ( keys %LaTeX::ToUnicode::Tables::ARGUMENT_COMMANDS ) {
        my $repl = $LaTeX::ToUnicode::Tables::ARGUMENT_COMMANDS{$cmd};
        my $lft = $repl->[0]; # ref to two-element list
        my $rht = $repl->[1];
        # \cmd{foo} -> LFT foo RHT
        $string =~ s/\\$cmd${endcw}\{(.*?)\}/$lft$1$rht/g;
        #warn "replaced arg $cmd, yielding $string\n";
    }
    
    $string;
}

#  Convert url commands in STRING. This is a special case of commands
# with arguments: \url{u} and \href{u}{desc text}. The HTML output
# (generated if $OPTIONS{html} is set) is just too special to be handled
# in a table; further, \href is the only two-argument command we are
# currently handling.
# 
sub _convert_urls {
    my ($string,$options) = @_;

    if ($options->{html}) {
        # HTML output.
        # \url{URL} -> <a href="URL">URL</a>
        $string =~ s,\\url$endcw\{([^}]*)\}
                    ,<a href="$1">$1</a>,gx;
        #
        # \href{URL}{TEXT} -> <a href="URL">TEXT</a>
        $string =~ s,\\href$endcw\{([^}]*)\}\s*\{([^}]*)\}
                    ,<a href="$1">$2</a>,gx;

    } else {
        # plain text output.
        # \url{URL} -> URL
        $string =~ s/\\url$endcw\{([^}]*)\}/$1/g;
        #
        # \href{URL}{TEXT} -> TEXT (URL)
        # but, as a special case, if URL ends with TEXT, just output URL,
        # as in:
        #   \href{https://doi.org/10/fjzzc8}{10/fjzzc8}
        # ->
        #   https://doi.org/10/fjzzc8
        # 
        # Yet more specialness: the TEXT might have extra braces, as in
        #   \href{https://doi.org/10/fjzzc8}{{10/fjzzc8}}
        # left over from previous markup commands (\path) which got
        # removed.  We want to accept and ignore such extra braces,
        # hence the \{+ ... \}+ in recognizing TEXT.
        # 
#warn "txt url: starting with $string\n";
        if ($string =~ m/\\href$endcw\{([^}]*)\}\s*\{+([^}]*)\}+/) {
          my $url = $1;
          my $text = $2;
#warn "   url: $url\n";
#warn "  text: $text\n";
          my $repl = ($url =~ m!$text$!) ? $url : "$text ($url)";
#warn "  repl: $repl\n";
          $string =~ s/\\href$endcw\{([^}]*)\}\s*\{+([^}]*)\}+/$repl/;
#warn "  str:  $string\n";
        }
    }
    
    $string;
}

#  Convert control words (not symbols), that is, a backslash and an
# alphabetic sequence of characters terminated by a non-alphabetic
# character. Following whitespace is ignored.
# 
sub _convert_control_words {
    my $string = shift;

    foreach my $command ( keys %LaTeX::ToUnicode::Tables::CONTROL_WORDS ) {
        my $repl = $LaTeX::ToUnicode::Tables::CONTROL_WORDS{$command};
        # replace {\CMD}, whitespace ignored after \CMD.
        $string =~ s/\{\\$command$endcw\}/$repl/g;
        
        # replace \CMD, preceded by not-consumed non-backslash.
        $string =~ s/(?<=[^\\])\\$command$endcw/$repl/g;
        
        # replace \CMD at beginning of whole string, which otherwise
        # wouldn't be matched. Two separate regexps to avoid
        # variable-length lookbehind.
        $string =~ s/^\\$command$endcw/$repl/g;
    }

    $string;
}

#  Convert control symbols, other than accents. Much simpler than
# control words, since are self-delimiting, don't take arguments, and
# don't consume any following text.
# 
sub _convert_control_symbols {
    my $string = shift;

    foreach my $symbol ( keys %LaTeX::ToUnicode::Tables::CONTROL_SYMBOLS ) {
        my $repl = $LaTeX::ToUnicode::Tables::CONTROL_SYMBOLS{$symbol};

        # because these are not alphabetic, we can quotemeta them,
        # and we need to because "\" is one of the symbols.
        my $rx = quotemeta($symbol);
        
        # the preceding character must not be a backslash, else "\\ "
        # could have the "\ " seen first as a control space, leaving
        # a spurious \ behind. Don't consume the preceding.
        # Or it could be at the beginning of a line.
        # 
        $string =~ s/(^|(?<=[^\\]))\\$rx/$repl/g;
        #warn "after sym $symbol (\\$rx -> $repl), have: $string\n";        
    }

    $string;
}

# Convert accents.
# 
sub _convert_accents {
    my $string = shift;
    
    # first the non-alphabetic accent commands, like \".
    my %tbl = %LaTeX::ToUnicode::Tables::ACCENT_SYMBOLS;
    $string =~ s/(\{\\(.)\s*\{(\\?\w{1,2})\}\})/$tbl{$2}{$3} || $1/eg; #{\"{a}}
    $string =~ s/(\{\\(.)\s*(\\?\w{1,2})\})/    $tbl{$2}{$3} || $1/eg; # {\"a}
    $string =~ s/(\\(.)\s*(\\?\w{1,1}))/        $tbl{$2}{$3} || $1/eg; # \"a
    $string =~ s/(\\(.)\s*\{(\\?\w{1,2})\})/    $tbl{$2}{$3} || $1/eg; # \"{a}
    
    # second the alphabetic commands, like \c. They have to be handled
    # differently because \cc is not \c{c}! The only difference in the
    # regular expressions is using $endcw instead of just \s*.
    # 
    %tbl = %LaTeX::ToUnicode::Tables::ACCENT_LETTERS;
    $string =~ s/(\{\\(.)$endcw\{(\\?\w{1,2})\}\})/$tbl{$2}{$3} || $1/eg; #{\"{a}}
    $string =~ s/(\{\\(.)$endcw(\\?\w{1,2})\})/    $tbl{$2}{$3} || $1/eg; # {\"a}
    $string =~ s/(\\(.)$endcw(\\?\w{1,1}))/        $tbl{$2}{$3} || $1/eg; # \"a
    $string =~ s/(\\(.)$endcw\{(\\?\w{1,2})\})/    $tbl{$2}{$3} || $1/eg; # \"{a}
    
    
    # The argument is just one \w character for the \"a case, not two,
    # because otherwise we might consume a following character that is
    # not part of the accent, e.g., a backslash (\"a\'e).
    # 
    # Others can be two because of the \t tie-after accent. Even {\t oo} is ok.
    # 
    # Allow whitespace after the \CMD in all cases, e.g., "\c c". Even
    # for the control symbols, it turns out spaces are ignored there
    # (as in \" o), unlike the usual syntax.
    # 
    # Some non-word constituents would work, but in practice we hope
    # everyone just uses letters.

    $string;
}

# For the [n]german package.
sub _convert_german {
    my $string = shift;

    foreach my $symbol ( keys %LaTeX::ToUnicode::Tables::GERMAN ) {
        $string =~ s/\Q$symbol\E/$LaTeX::ToUnicode::Tables::GERMAN{$symbol}/g;
    }
    $string;
}

# Control words that produce printed symbols (and letters in languages
# other than English), that is.
# 
sub _convert_symbols {
    my $string = shift;

    foreach my $symbol ( keys %LaTeX::ToUnicode::Tables::SYMBOLS ) {
        my $repl = $LaTeX::ToUnicode::Tables::SYMBOLS{$symbol};
        # preceded by a (non-consumed) non-backslash,
        # usual termination for a control word.
        # These commands don't take arguments.
        $string =~ s/(?<=[^\\])\\$symbol$endcw/$repl/g;
        
        # or the beginning of the whole string:
        $string =~ s/^\\$symbol$endcw/$repl/g;
    }
    $string;
}

# Special character sequences, not \commands. They aren't all
# technically ligatures, but no matter.
# 
sub _convert_ligatures {
    my $string = shift;

    # have to convert these in order specified.
    my @ligs = @LaTeX::ToUnicode::Tables::LIGATURES;
    for (my $i = 0; $i < @ligs; $i+=2) {
        my $in = $ligs[$i];
        my $out = $ligs[$i+1];
        $string =~ s/\Q$in\E/$out/g;
    }
    $string;
}

# 
# Convert LaTeX markup commands in STRING like \textbf{...} and
# {\bfshape ...} and {\bf ...}.
# 
# If we're aiming for plain text output, they are just cleared away (the
# braces are not removed).
# 
# If we're generating HTML output ("html" key is set in $OPTIONS hash
# ref), we use the value in the hash, so that \textbf{foo} becomes
# <b>foo</b>. Nested markup doesn't work.
# 
sub _convert_markups {
    my ($string, $options) = @_;
    
    # HTML is different.
    return _convert_markups_html($string) if $options->{html};
    
    # Not HTML, so here we'll "convert" to plain text by removing the
    # markup commands.

    # we can do all the markup commands at once.
    my $markups = join('|', keys %LaTeX::ToUnicode::Tables::MARKUPS);
    
    # Remove \textMARKUP{...}, leaving just the {...}
    $string =~ s/\\text($markups)$endcw//g;

    # Similarly remove \MARKUPshape, plus remove \upshape.
    $string =~ s/\\($markups|up)shape$endcw//g;

    # Remove braces and \command in: {... \MARKUP ...}
    $string =~ s/(\{[^{}]+)\\(?:$markups)$endcw([^{}]+\})/$1$2/g;

    # Remove braces and \command in: {\MARKUP ...}
    $string =~ s/\{\\(?:$markups)$endcw([^{}]*)\}/$1/g;

    # Remove: {\MARKUP
    # Although this will leave unmatched } chars behind, there's no
    # alternative without full parsing, since the bib entry will often
    # look like: {\em {The TeX{}book}}. Also might, in principle, be
    # at the end of a line.
    $string =~ s/\{\\(?:$markups)$endcw//g;

    # Ultimately we remove all braces in ltx2crossrefxml SanitizeText fns,
    # so the unmatched braces don't matter ... that code should be moved.

    $string;
}

# Convert \markup in STRING to html. We can't always figure out where to
# put the end tag, but we always put it somewhere. We don't even attempt
# to handle nested markup.
# 
sub _convert_markups_html {
    my ($string) = @_;
    
    my %MARKUPS = %LaTeX::ToUnicode::Tables::MARKUPS;
    # have to consider each markup \command separately.
    for my $markup (keys %MARKUPS) {
        my $hcmd = $MARKUPS{$markup}; # some TeX commands don't translate
        my $tag = $hcmd ? "<$hcmd>" : "";
        my $end_tag = $hcmd ? "</$hcmd>" : "";
        
        # The easy one: \textMARKUP{...}
        $string =~ s/\\text$markup$endcw\{(.*?)\}/$tag$1$end_tag/g;

        # {x\MARKUP(shape) y} -> x<mk>y</mk> (leave out braces)
        $string =~ s/\{([^{}]+)\\$markup(shape)?$endcw([^{}]+)\}
                    /$1$tag$3$end_tag/gx;

        # {\MARKUP(shape) y} -> <mk>y</mk>. Same as previous but without
        # the x part. Could do it in one regex but this seems clearer.
        $string =~ s/\{\\$markup(shape)?$endcw([^{}]+)\}
                    /$tag$2$end_tag/gx;
        
        # for {\MARKUP(shape) ... with no matching brace, we don't know
        # where to put the end tag, so seems best to do nothing.
    }
    
    $string;
}


##############################################################
#  debug_hash_as_string($LABEL, HASH)
#
# Return LABEL followed by HASH elements, followed by a newline, as a
# single string. If HASH is a reference, it is followed (but no recursive
# derefencing).
###############################################################
sub debug_hash_as_string {
    my ($label) = shift;
    my (%hash) = (ref $_[0] && $_[0] =~ /.*HASH.*/) ? %{$_[0]} : @_;

    my $str = "$label: {";
    my @items = ();
    for my $key (sort keys %hash) {
        my $val = $hash{$key};
        $val = ".undef" if ! defined $val;
        $key =~ s/\n/\\n/g;
        $val =~ s/\n/\\n/g;
        push (@items, "$key:$val");
    }
    $str .= join (",", @items);
    $str .= "}";

    return "$str\n";
}

1;

__END__
=pod

=encoding UTF-8

=head1 NAME

LaTeX::ToUnicode - Convert LaTeX commands to Unicode

=head1 VERSION

version 0.54

=head1 SYNOPSIS

  use LaTeX::ToUnicode qw( convert debuglevel $endcw );

  # simple examples:
  convert( '{\"a}'              ) eq 'ä';      # true
  convert( '{\"a}', entities=>1 ) eq '&#00EF;'; # true
  convert( '"a', german=>1      ) eq 'ä';      # true, `german' package syntax
  convert( '"a',                ) eq '"a';      # false, not enabled by default
  
  # more generally:
  my $latexstr;
  my $unistr = convert($latexstr);  # get literal (binary) Unicode characters

  my $entstr = convert($latexstr, entities=>1);          # get &#xUUUU;
  
  my $htmstr = convert($latexstr, entities=>1, html=>1); # also html markup
  
  my $unistr = convert($latexstr, hook=>\&my_hook); # user-defined hook
  
  # if nonzero, dumps various info; perhaps other levels in the future.
  LaTeX::ToUnicode::debuglevel($verbose);

  # regexp for terminating TeX control words, e.g., in hooks.
  my $endcw = $LaTeX::ToUnicode::endcw;
  $string =~ s/\\newline$endcw/ /g; # translate \newline to space
  
=head1 DESCRIPTION

This module provides a method to convert LaTeX markups for accents etc.
into their Unicode equivalents. It translates some commands for special
characters or accents into their Unicode (or HTML) equivalents and
removes formatting commands. It is not at all bulletproof or complete.

This module is intended to convert fragments of LaTeX source, such as
bibliography entries and abstracts, into plain text (or, optionally,
simplistic HTML). It is not a document conversion system. Math, tables,
figures, sectioning, etc., are not handled in any way, and mostly left
in their TeX form in the output. The translations assume standard LaTeX
meanings for characters and control sequences; macros in the input are
not considered.

The aim for all the output is utter simplicity and minimalism, not
faithful translation. For example, although Unicode has a code point for
a thin space, the LaTeX C<\thinspace> (etc.) command is translated to
the empty string; such spacing refinements desirable in the TeX output
are, in our experience, generally not desired in the HTML output from
this tool.

As another example, TeX C<%> comments are not removed, even on lines by
themselves, because they may be inside verbatim blocks, and we don't
attempt to keep any such context. In practice, TeX comments are rare in
the text fragments intended to be handled, so removing them in advance
has not been a great burden.

As another example, LaTeX ties, C<~> characters, are replaced with
normal spaces (exception: unless they follow a C</> character or at the
beginning of a line, when they're assumed to be part of a url or a
pathname), rather than a no-break space character, because in our
experience most ties intended for the TeX output would just cause
trouble in plain text or HTML.

Regarding normal whitespace: all leading and trailing horizontal
whitespace (that is, SPC and TAB) is removed. All internal horizontal
whitespace sequences are collapsed to a single space.

After the conversions, all brace characters (C<{}>) are simply removed
from the returned string. This turns out to be a significant convenience
in practice, since many LaTeX commands which take arguments don't need
to do anything for our purposes except output the argument.

On the other hand, backslashes are not removed. This is so the caller
can check for C<\\> and thus discover untranslated commands. Of course
there are many other constructs that might not be translated, or
translated wrongly. There is no escaping the need to carefully look at
the output.

Suggestions and bug reports are welcome for practical needs; we know
full well that there are hundreds of commands not handled that could be.
Virtually all the behavior mentioned here would be easily made
customizable, if there is a need to do so.

=head1 FUNCTIONS

=head2 convert( $latex_string, %options )

Convert the text in C<$latex_string> into a plain(er) Unicode string.
Escape sequences for accented and special characters (e.g., C<\i>,
C<\"a>, ...) are converted. A few basic formatting commands (e.g.,
C<{\it ...}>) are removed. See the L<LaTeX::ToUnicode::Tables> submodule
for the full conversion tables.

These keys are recognized in C<%options>:

=over

=item C<entities>

Output C<&#xUUUU;> entities (valid in XML); in this case, also convert
the E<lt>, E<gt>, C<&> metacharacters to entities. Recognized non-ASCII
Unicode characters in the original input are also converted to entities,
not only the translations from TeX commands.

The default is to output literal (binary) Unicode characters, and
not change any metacharacters.

=item C<german>

If this option is set, the commands introduced by the package `german'
(e.g. C<"a> eq C<ä>, note the missing backslash) are also
handled.

=item C<html>

If this option is set, the output is simplistic html rather than plain
text. This affects only a few things: S<1) the> output of urls from
C<\url> and C<\href>; S<2) the> output of markup commands like
C<\textbf> (but nested markup commands don't work); S<3) two> other
random commands, C<\enquote> and C<\path>, because they are needed.

=item C<hook>

The value must be a function that takes two arguments and returns a
string. The first argument is the incoming string (may be multiple
lines), and the second argument is a hash reference of options, exactly
what was passed to this C<convert> function. Thus the hook can detect
whether html is needed.

The hook is called (almost) right away, before any of the other
conversions have taken place. That way the hook can make use of the
predefined conversions instead of repeating them. The only changes made
to the input string before the hook is called are trivial: leading and
trailing whitespace (space and tab) on each line are removed, and, for
HTML output, incoming ampersand, less-than, and greater-than characters
are replaced with their entities.

Any substitutions that result in Unicode code points must use
C<\\x{nnnn}> on the right hand side: that's two backslashes and a
four-digit hex number.

As an example, here is a skeleton of the hook function for TUGboat:

  sub LaTeX_ToUnicode_convert_hook {
    my ($string,$options) = @_;

    my $endcw = $LaTeX::ToUnicode::endcw;
    die "no endcw regexp in LaTeX::ToUnicode??" if ! $endcw;

    ...
    $string =~ s/\\newline$endcw/ /g;

    # TUB's \acro{} takes an argument, but we do nothing with it.
    # The braces will be removed by convert().
    $string =~ s/\\acro$endcw//g;
    ...
    $string =~ s/\\CTAN$endcw/CTAN/g;
    $string =~ s/\\Dash$endcw/\\x{2014}/g; # em dash; replacement is string
    ...

    # ignore \begin{abstract} and \end{abstract} commands.
    $string =~ s,\\(begin|end)$endcw\{abstract\}\s*,,g;

    # Output for our url abbreviations, and other commands, depends on
    # whether we're generating plain text or HTML.
    if ($options->{html}) {
        # HTML.
        # \tbsurl{URLBASE} -> <a href="https://URLBASE">URLBASE</a>
        $string =~ s,\\tbsurl$endcw\{([^}]*)\}
                    ,<a href="https://$1">$1</a>,gx;
        ...
        # varepsilon, and no line break at hyphen.
        $string =~ s,\\eTeX$endcw,\\x{03B5}<nobr>-</nobr>TeX,g;

    } else {
        # for plain text, we can just prepend the protocol://.
        $string =~ s,\\tbsurl$endcw,https://,g;
        ...
        $string =~ s,\\eTeX$endcw,\\x{03B5}-TeX,g;
    }
    ...
    return $string;
  }

As shown here for C<\eTeX> (an abbreviation macro defined in the
TUGboat style files), if markup is desired in the output, the
substitutions must be different for HTML and plain text. Otherwise, the
desired HTML markup is transliterated as if it were plain text. Or else
the translations must be extended so that TeX markup can be used on the
rhs to be replaced with the desired HTML (C<&lt;nobr&gt;> in this case).

For the full definition (and plenty of additional information),
see the file C<ltx2crossrefxml-tugboat.cfg> in the TUGboat source
repository at
<https://github.com/TeXUsersGroup/tugboat/tree/trunk/capsules/crossref>.

The hook function is specified in the C<convert()> call like this:

  LaTeX::ToUnicode::convert(..., { hook => \&LaTeX_ToUnicode_convert_hook })

=back

=head2 debuglevel( $level )

Output debugging information if C<$level> is nonzero.

=head2 $endcw

A predefined regexp for terminating TeX control words (not control
symbols!). Can be used in, for example, hook functions:

  my $endcw = $LaTeX::ToUnicode::endcw;
  $string =~ s/\\newline$endcw/ /g; # translate \newline to space

It's defined as follows:

  our $endcw = qr/(?<=[a-zA-Z])(?=[^a-zA-Z]|$)\s*/;

That is, look behind for an alphabetic character, then look ahead for a
non-alphabetic character (or end of line), then consume whitespace.
Fingers crossed.

=head1 AUTHOR

Gerhard Gossen <gerhard.gossen@googlemail.com>,
Boris Veytsman <boris@varphi.com>,
Karl Berry <karl@freefriends.org>

L<https://github.com/borisveytsman/bibtexperllibs>

=head1 COPYRIGHT AND LICENSE

Copyright 2010-2023 Gerhard Gossen, Boris Veytsman, Karl Berry

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl5 programming language system itself.

=cut
