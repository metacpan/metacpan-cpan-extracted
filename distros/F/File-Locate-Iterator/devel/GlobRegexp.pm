# Copyright 2009 Kevin Ryde.
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


# Per info node "(find)Shell Pattern Matching", not the same as Text::Glob.
#     *             -- 0 or more chars, including /
#     ?             -- 1 char, including /
#     [abc]         -- char class
#     [^abc],[!abc] -- negated char class
#     \             -- remove special meaning, incl in char class
#
sub _fnmatch_to_regex_string {
  my ($str) = @_;

  if ($str !~ /[*?[]/) {
    return quotemeta($str);
  }

  $str =~ s{(\[(?:\\.|[^\\\]])*\])  # $1 char class
            |\\(.)                  # $2 backslashed
            |([*?]+)                # $3 * and ?
            |(\W)}{                 # $4 other non-plain
    (defined $1   ? _fnmatch_char_class_to_regex($1)
     : defined $2 ? quotemeta($2)
     : defined $3 ? _star_quest_to_regex_string($3)
     : quotemeta($4))
      }xsge;

  $str = '^'.$str.'$';

  # optimize away leading "^.*" or trailing ".*$"
  $str =~ s/^\^\.\*//;
  $str =~ s/\.\*\$$//;

  # optimize leading ^.{2,} to .{2} etc, and same trailing
  $str =~ s/\.\{(\d+),}\$$/.{$1}/;
  $str =~ s/^\^\.\{(\d+),}/.{$1}/;

  return $str;
}
sub _star_quest_to_regex_string {
  my ($str) = @_;
  my $min = ($str =~ tr/?/?/); # count of '?'s in $str
  my $star = ($min != length($str));
  if ($star) {
    if ($min == 0) {
      return ".*";
    } else {
      return ".{$min,}";
    }
  } else {
    if ($min == 1) {
      return ".";
    } else {
      return ".{$min}";
    }
  }
}
sub _fnmatch_char_class_to_regex {
  my ($str) = @_;
  $str =~ s/^\[!/[^/;    # [! negation -> [^
  $str =~ s/\\(\w)/$1/g; # \ backslashed word char -> unbackslashed literal
  return $str;
}




#-----------------------------------------------------------------------------
# _glob_to_regex_string()

foreach my $elem (['.pm',        '\\.pm'],
                  ['*.pm',       '\\.pm$'],

                  ['?.pm',  '^.\\.pm$'],

                  # even a backslashed ? provokes anchoring
                  ['\\?.pm',  '^\\?\\.pm$'],

                  ['[abc].pm',   '^[abc]\\.pm$'],
                  ['[^abc].pm', '^[^abc]\\.pm$'],

                  # not recognised by Text::Glob
                  # ['[!abc].pm', '^[^abc]\\.pm$'],

                  ['[a*c].pm',   '^[a*c]\\.pm$'],
                 ) {
  ## no critic (ProtectPrivateSubs)
  my ($glob, $want) = @$elem;
  my $got = File::Locate::Iterator::_glob_to_regex_string($glob);
  is ($got, $want, "glob: $glob");
}


1;
__END__
