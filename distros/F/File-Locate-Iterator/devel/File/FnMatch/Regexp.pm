# Copyright 2009, 2010 Kevin Ryde.
#
# This file is part of File-Locate-Iterator.
#
# File-Locate-Iterator is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# File-Locate-Iterator is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with File-Locate-Iterator; see the file COPYING.  Failing that, go to
# <http://www.gnu.org/licenses/>.


package File::FnMatch::Regexp;
use strict;
use warnings;
use Carp;
use vars '$VERSION';

$VERSION = 0;

# uncomment this to run the ### lines
#use Smart::Comments;

BEGIN {
  if ($] >= 5.006) {
    eval <<'HERE' or die $@;
    sub pattern_to_regex {
      my $str = pattern_to_regex_string(@_);
      return qr/$str/;
    } 1
HERE
  }
}

# Text::Glob
# "(libc)Wildcard Matching"
# Regexp::Optimizer

my %extclose = ('?' => ')?',
                '*' => ')*',
                '+' => ')+');

sub pattern_to_regex_string {
  my ($str, %opt) = @_;

  # FNM_PERIOD
  #    "*" or "?" at the start of the pattern don't match a "." at start of
  #    the target, to exclude dot files like ".somethingrc"
  # FNM_FILE_NAME
  #    * and ? don't match /
  # FNM_PERIOD + FNM_FILE_NAME
  #    * and ? don't match a "/", plus
  #    * and ? don't match a "." at start, nor after a "/"

  my $escapes = ! $opt{'FNM_NOESCAPE'};
  my $extmatch = $opt{'FNM_EXTMATCH'};
  my $allow_slash = ! ($opt{'FNM_FILE_NAME'} || $opt{'FNM_PATHNAME'});
  my $allow_dotfiles = ! $opt{'FNM_PERIOD'};
  my $posixly_correct = $opt{'POSIXLY_CORRECT'};

  #   if (defined $posixly_correct && $posixly_correct eq 'use_ENV') {
  #     $posixly_correct = defined $ENV{'POSIXLY_CORRECT'};
  #   }
  #   if ($opt{'POSIXLY_CORRECT_FROM_ENV'}) {
  #     $posixly_correct = defined $ENV{'POSIXLY_CORRECT'};
  #   }

  # pattern to match a single char
  my $anychar = ($allow_dotfiles
                 ? ($allow_slash
                    ? '.'
                    : '[^/]')   # no slashes
                 : ($allow_slash
                    ? '(?:[^.]|(?<!^)\.)'              # no dot start
                    : '(?:[^/.]|(?<!/)\.|(?<!^)\.)')); # no slash or dot start

  # pattern to match a single char when not at the start of the string and
  # therefore the dotfile handling there can simplify
  my $anychar_not_start = ($allow_dotfiles
                           ? $anychar
                           : ($allow_slash
                              ? '.'                     # no dot start
                              : '(?:[^/.]|(?<!/)\.)')); # no slash or dot start

  # pattern for a negated char class, either ^ or ! for GNU, but only ! for
  # strict POSIX
  my $classneg = ($opt{'POSIXLY_CORRECT'} ? '!' : '[!^]');

  my $re = '^(?s' . ($opt{'FNM_CASEFOLD'} ? 'i' : '-i') . ':';
  my @extend;

  pos($str) = 0;
  while (pos($str) < length($str)) {
    #     if ($str =~ /\G([^[\\?*+\@!]+)/cg) {  # run of non-specials
    #       $re .= quotemeta($1);
    #       if (! @extend) { $anychar = $anychar_not_start; }
    #
    #     } els

    if ($str =~ /\G\[/cg) {  # character class [abc] etc
      $re .= '[';
      if ($str =~ /\G$classneg/cg) {
        $re .= '^';
        if (! $allow_dotfiles) { $re .= '.'; }
        if (! $allow_slash)    { $re .= '/'; }
      }
      until ($str =~ /\G(]|$)/cg) {
        if ($str =~ /\G(\[:\w+:])/cg) {
          $re .= $1;
        } elsif ($escapes && $str =~ /\G\\(.)/cg) {  # backslashed
          $re .= quotemeta($1);
        } else {  # single char
          $str =~ /\G(.)/cg or die "Oops, no more chars";
          $re .= ($1 eq '-' ? $1 : quotemeta($1));
        }
      }
      $re .= ']';
      if (! @extend) { $anychar = $anychar_not_start; }

    } elsif ($extmatch && $str =~ /\G([?*+@!])\(/cg) {
      # extended ?(x|y) +(x|y) etc
      push @extend, $extclose{$1} || ')';
      if ($1 eq '!') {
        $re .= '?!';  # (?! negative look-ahead
      } else {
        $re .= '(?:';
      }
    } elsif (@extend && $str =~ /\G\|/cg) {
      $re .= '|';
    } elsif (@extend && $str =~ /\G\)/cg) {
      $re .= pop @extend;

    } elsif ($str =~ /\G\*/cg) {   # * zero or more chars
      $re .= $anychar . '*';
    } elsif ($str =~ /\G\?/cg) {   # ? one char
      $re .= $anychar;
      if (! @extend) { $anychar = $anychar_not_start; }

    } else {
      ($escapes && $str =~ /\G\\(.)/cg)
        || ($str =~ /\G(.)/cg)
          || die "Oops, no more chars?";
      $re .= quotemeta($1);
      if (! @extend) { $anychar = $anychar_not_start; }
    }
  }

  $re .= join ('', reverse @extend) . ')$';
  if ($opt{'FNM_LEADING_DIR'}) {
    $re .= '|/';
  }
  return $re;

  #   my $classchar = ($opt{'FNM_NOESCAPE'}
  #                    ? '(?:[:\w+:]|[^]])'
  #                    : '(?:\\\\.|[:\w+:]|[^]])');
  #
  #   my $escapee = ($opt{'FNM_NOESCAPE'}
  #                  ? '\\W'
  #                  : '\\+.|[^\\\\[:word:]]');
  #
  #   $str =~ s{\[($classchar*)(?:]|$)  # $1 char class
  #           |([*?]+)                  # $2 * and ? runs
  #           |($escapee)               # $3 backslashed or other non-plain
  #          }{
  #            (defined $1   ? _char_class($1,\%opt)
  #             : defined $2 ? _star_quest($2,\%opt)
  #             : quotemeta(substr($3,-1,1)))
  #          }xsge;

  #   $str = '^'.$str;
  #   if ($opt{'FNM_LEADING_DIR'}) {
  #     $str .= '$|/';
  #   } else {
  #     $str .= '$';
  #   }


  # optimize leading or trailing
  #   .*    -> nothing
  #   .{1,} -> .
  #   .{N,} -> .{N}
  #
  #   $str =~ s/\.\*\$$//
  #     or $str =~ s/\.\{1,}\$$/./
  #       or $str =~ s/\.\{(\d+),}\$$/.{$1}/;
  #   $str =~ s/^\^\.\*//
  #     or $str =~ s/^\^\.\{1,}/./
  #       or $str =~ s/^\^\.\{(\d+),}/.{$1}/;

  #   $str = "(?s" . ($opt{'FNM_CASEFOLD'} ? 'i' : '') . ":$str)";
  #
  #   return $str;
}
sub _char_class {
  my ($str, $opt) = @_;
  ### _char_class: $str

  my $neg = ($opt->{'POSIXLY_CORRECT'} ? '!' : '[!^]');
  $neg = ($str =~ s{^$neg}{} ? '^' : '');

  # in particular must unescape \w etc so as not to get perl classes
  if (! $opt->{'FNM_NOESCAPE'}) {
    $str =~ s{\\(.)}{$1}g;
  }

  # quotemeta except leave '-' alone
  $str =~ s{([^-[:word:]])}{\\$1};
    
  return "[$neg\Q$str\E]";
}
sub _star_quest {
  my ($str, $opt) = @_;
  my $star = ($str =~ tr/*//d);

  my $anychar = ($opt->{'FNM_FILE_NAME'} || $opt->{'FNM_PATHNAME'}
                 ? '[^/]'
                 : '.');
  $str = $anychar x length($str);

  if ($opt->{'FNM_PERIOD'}) {
    my $anynotdot = ($opt->{'FNM_FILE_NAME'} || $opt->{'FNM_PATHNAME'}
                     ? '[^/.]'
                     : '[^.]');
    if ($str eq '') {
      $str = '$'.$anynotdot;
    } else {
      substr ($str,0,1, $anynotdot);
      # $min--;
    }
  }
  if ($star) {
    $str .= "$anychar*";
  }
  return $str;

  # my $min = ($str =~ tr/?/./); # count of '?'s in $str
  # $min != length($str));
  #
  #   if ($star) {
  #     if ($min == 0) {
  #       return "$pre*";
  #     } else {
  #       return "$pre{$min,}";
  #     }
  #   } else {
  #     if ($min == 1) {
  #       return $pre;
  #     } else {
  #       return "{$min}";
  #     }
  #   }
}
sub _backslashed {
  my ($str) = @_;
  $str =~ s{^((\\\\)+)\\?(.)}
           { $1 . quotemeta($3)}es;
  return $str;
}

1;
__END__

=head1 NAME

File::FnMatch::Regexp - fnmatch style globs using regexps

=head1 SYNOPSIS

 use File::FnMatch::Regexp;
 my $re = File::FnMatch::Regexp::glob_to_regex('*.c');

 use File::FnMatch::Regexp ':all';
 my $restr = glob_to_regex_string('[0-9]*.txt');

=head1 DESCRIPTION

This module turns C<fnmatch> style glob patterns into Perl regexps.

=head1 EXPORTS

Nothing is exported by default, but the functions or C<:all> can be asked
for in usual C<Exporter> style,

    use File::FnMatch::Regexp 'glob_to_regex';

    use File::FnMatch::Regexp ':all';

=head1 FUNCTIONS

=over 4

=item C<$qr_re = glob_to_regex ($glob_pattern, key=E<gt>value, ...)>

=item C<$str_re = glob_to_regex_string ($glob_pattern, key=E<gt>value, ...)>

Return a Perl regular expression equivalent to C<$glob_pattern>.

C<glob_to_regex> returns a C<qr//> style compiled regexp,
C<glob_to_regex_string> returns just a string.  C<qr//> is new in Perl 5.6,
so C<glob_to_regex> is only available in 5.6 and up.

The following key/value style options are available,

=over 4

=item C<POSIXLY_CORRECT> (boolean)

Follow the POSIX standard, without GNU extensions.

The only GNU extension currently applied is "^" for negated character
classes like "[^abc]" in addition to the POSIX standard "!" like "[!abc]".
With C<POSIXLY_CORRECT> the "^" is an ordinary char.

=item C<FNM_PERIOD> (boolean)

Wildcards don't match dotfiles.

With this option for example "*rc" doesn't match F<.foorc>.  Negated char
classes similarly, so "[^z]foorc" doesn't match F<.foorc> either
(effectively a "." is added to the set of characters not to match).

An explicit dot at the start of C<$glob> can always be used (with or without
C<FNM_PERIOD>), so for example ".foo*" always matches F<.foorc>.

This option is currently implemented with Perl's "negative look-behind"
feature which means the resulting regexps require Perl 5.005 or higher.

=item C<FNM_FILE_NAME> (boolean)

=item C<FNM_PATHNAME> (boolean)

Wildcards don't match "/" directory separators.

With this option for example "x*.c" doesn't match "xx/yy.c", whereas
otherwise it would.  Similarly negated char classes so "x[^y]z.c" doesn't
match "x/z.c" (effectively a "/" is added to the set of characters not to
match).

If both C<FNM_FILE_NAME> and C<FNM_PERIOD> are set, then in addition
wildcards don't match dotfiles after a "/".  For example "/tmp/*zy" doesn't
match "/tmp/.xyzzy" (whereas with C<FNM_FILE_NAME> alone, or C<FNM_PERIOD>
alone, it does).

The combination C<FNM_FILE_NAME> and C<FNM_PERIOD> is the traditional style
for filename expansion in the shell, ie. F</bin/sh>.  (Advanced shells like
C<bash> or C<zsh> have more special forms than plain C<fnmatch> though.)

=item C<FNM_NOESCAPE> (boolean)

Make backslash an ordinary char, not an escape.

=item C<FNM_EXTMATCH> (boolean)

Recognise the following C<ksh> style special forms,

    ?(GLOBS)      zero or one
    *(GLOBS)      zero or more
    +(GLOBS)      one or more
    @(GLOBS)      one match
    !(GLOBS)      no match lookahead

These are repetitions similar to regexp style "?", "*" and "+", but with the
"+" etc before instead of after the sub-expression.

For example "?(foo)bar.c" makes "foo" optional and so matches "foobar.c" or
"bar.c".  Repetition "b*(an)a.c" matches "bana.c", "banana.c", "bananana.c"
etc.

C<GLOBS> can be a single glob or alternatives separated by a "|", any of
which can satisfy the match.  So for example "cat@(s|ty).c" matches either
"cats.c" or "catty.c".

C<!()> non-match means for example "x!(yz).c" matches "x.c" and "xy.c", but
not "xyz.c".  This is like Perl's "zero-width negative look-ahead" feature
(see L<perlre/Look-Around Assertions>), and is in fact currently implemented
that way.

=back

=back

=head1 OTHER WAYS TO DO IT

C<File::FnMatch> calls the C library C<fnmatch>, which will be smaller and
faster if you just want to match instead of getting a regexp to further
manipulate.

C<Text::Glob> which comes with Perl does a simpler glob to regexp
transformation, without character classes, and without the dotfile etc
options.

=head1 SEE ALSO

L<File::FnMatch>, L<Text::Glob>

=head1 HOME PAGE

http://user42.tuxfamily.org/file-locate-iterator/index.html

=head1 LICENCE

Copyright 2009, 2010 Kevin Ryde

File-Locate-Iterator is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

File-Locate-Iterator is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
File-Locate-Iterator; see the file F<COPYING>.  If not, see
http://www.gnu.org/licenses/

=cut
