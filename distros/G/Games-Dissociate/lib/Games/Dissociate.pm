### The POD is at the end. ###
require 5.000;
package Games::Dissociate;
use strict;
require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK $Debug $VERSION);
use Carp;
@ISA = qw(Exporter);
@EXPORT = qw(dissociate_filter dissociate);
$VERSION = 1.0;
$Debug = 0;

###########################################################################

sub dissociate_filter {
  require Text::Wrap;
  require Getopt::Std;
  my %o;
  if(@ARGV) {
    Getopt::Std::getopts('c:w:m:', \%o)
     or die "Options:
  -cNUMBER
      Run a by-character dissociation with that number of
      characters as the group size.
  -wNUMBER
      Run a by-word dissociation with that number of
      words as the group size.
  -mNUMBER
      Specifies how many iterations the dissociator loop should make.
";
  }

  my $o;
  my $max;
  if($_[0]) {
    $o = $_[0];
  } elsif($o{'w'}){
    $o = - abs($o{'w'});
  } elsif($o{'c'}){
    $o =   abs($o{'c'});
  }
  $o ||= 2;

  if($_[1]) {
    $max = $_[1];
  } elsif ($o{'m'}) {
    $max = abs($o{'m'});
  }
  $max ||= 100;

  print "group_length: $o.  max_length: $max\n" if $Debug;
  print Text::Wrap::wrap(   '','', dissociate(join('', <>), $o, $max)  ), "\n";
  return;
}

#==========================================================================
sub dissociate {
  my $in = $_[0];
  my $arg = int($_[1] || 2);
  my $iteration_limit = $_[2] || 100;
  my @out;

  my $by_word = ($arg < 0);
  my $degree = abs($arg);
  my $last_match_point;

  $degree = 2 if $degree == 1;

  use locale;

  $in =~ tr<\cm\cj \t>< >s;
  die "No input\n" unless length $in;
  study $in;

  my $new_matcher;
  if($by_word) {
    $new_matcher = "\\W+(" . join("\\W+", ("\\w+") x $degree) . ")";
  } else {
    $new_matcher = "(" . ('.' x $degree) . ")";
  }

  # In use in the loop.
  my($re, @orig, $matched, $remainder,
     $i, $last_matched, $iteration);
  $iteration = 0;

  $last_match_point = -1;
  while($iteration < $iteration_limit) {
    ++$iteration;
    if($last_matched) { # last thing we matched -- '' means take a stab
      $last_match_point = pos($in);
      if($by_word) { # By word...
        @orig = map(quotemeta($_), $last_matched =~ m/(\w+)/sg );
        $re =  "\\b"
               . join("\\W+",  @orig) # overlap
               . "\\W+("
               . join("\\W+", ("\\w+") x  $degree) # new tokens
               . ")(\\W+)"
        ;
        $matched = $remainder = '';
        $last_match_point = pos($in);

        if($in =~ m/$re/sig  ||  $in =~ m/$re/sig) {
          $matched = $1;
          $remainder = $2;
        }

      } else { # By char...
        @orig = map(quotemeta($_), $last_matched =~ m/(.)/sg );
        $re =    join('', @orig)     # overlap
               . '('
               . ("." x  $degree)    # new tokens
               . ')';

        $matched = $1  if $in =~ m/$re/sig  ||  $in =~ m/$re/sig;
      }

      if( $last_match_point == pos($in)  # This was a hapax legomenon.
          ||  pos($in) == 0              # We didn't match anything.

          # hm, this seems to be not just unnecessary, but BAD.
          #  ||  abs($last_match_point - pos($in)) < length($in)
      )
      {
        print "Hm, dead end at pos ", (0 + pos($in)), "\n" if $Debug;

        $last_matched = '';
        next;
      }

      $last_matched = $matched;
      print "Matched ($matched) at ", pos($in), "\n" if $Debug;
      push @out, $by_word ? ($last_matched . $remainder)
                          :  $last_matched;
      next;

    } else {
      # We don't have a last_matched -- take a stab.
      my($frame, $frame_size);
      pos($in) = 0;  # Ever necessary?
      if($by_word) {
        $frame_size =  ($degree + 3) * 8;
          # Generously assume 8 chars per word.
      } else {
        $frame_size =  ($degree + 1) * 4;
          # Generously assume 4 bytes per "." char.
      }

      my $i = int(rand(length($in) - $frame_size));
      pos($in) = $i;
      print "Taking a stab at pos $i\n" if $Debug;
      if(   $in =~ m/$new_matcher/isg
         || $in =~ m/$new_matcher/isg )  # Yes, try TWICE!  Magic, wooo.
      {
        $last_matched = $1;
      } else {
        print "Can't get an initial $degree-token match" if $Debug;
        last;
      }
    }

  } # end while

  return join('', @out);
}

#==========================================================================
1;

__END__

=head1 NAME

Games::Dissociate - a Dissociated Press algorithm and filter

=head1 SYNOPSIS

    use Games::Dissociate;
    ...
    $brilliant_prose = dissociate($normal_prose);

or

    perl -MGames::Dissociate -e dissociate_filter meno.txt

=head1 ABSTRACT

This module provides the function C<dissociate>, which implements a
Dissociated Press algorithm, well known to Emacs users as "meta-x
dissociate".  The algorithm here is by no means a straight port of
Emacs's C<dissociate.el>, but is instead merely inspired by it.

(I actually intended to make it a straight port, but couldn't manage
it -- the code in C<dissociate.el> is totally uncommented, and is
I<especially> obscure Lisp.)

This module also provides a procedure C<dissociate_filter>, for use in
the one-liner context:

  perl -MGames::Dissociate -e 'dissociate_filter(2)'
    < thesis.txt  > snip.txt

or

  perl -MGames::Dissociate -e 'dissociate_filter(-2)'
    < thesis.txt  > snip.txt

or in a script consisting of

  #!/usr/local/bin/perl
  use Games::Dissociate;  dissociate_filter;

=head2 Sample Dissociation

I got this text from feeding the UNIX man page for "regexp" (in
plaintext) to C<dissociate> with a $group_size parameter of 3:

=over

nd of then the full list of the more branch is zero or "*", "."
(matching thand regexp(n) right initional argumented by a pieces of
the left to match that (ab|a) general other worDS match to the first,
followed by "?". It matcheS In of the next start was been could
exp. The characters in expreSSIons belowed in the full matching the in
starticular EXpression in "[0-9]" include a list of sequence of the
are may before the regexp even therwise. REgexp(n) Tcl regular
expression to regexp(n) regexp(n) right. Input string), "\",

=back

=head2 About Dissociated Press algorithms

"Dissociated Press" algorithms produce text with token-patterns
(patterns of words, or patterns of characters) similar those found to
an input text.

This may be implemented in terms of Markov chains (basically,
statistical modeling of frequency of token-groups), altho both this
module and Emacs's C<dissociate.el> take shortcuts to avoid having to
construct and manipulate a real statistical model of the input text.

Basically, the way Dissociated Press algorithms (at least mine -- I
can't speak for the exact details of all others) work is:

=over

1. Start at a random point in the text, and read a group of tokens
(characters or words from there -- where group size is a parameter you
change) from there.  Call this the last-matched group.

2. Output the last-matched group.

3. Look for the other times the last-matched group occurs in the text,
and randomly select one of them.  (Or: select the I<next> time that
group occurs -- a shortcut I've made in the code, which seems to still
produce random-looking results).  Look at the group of tokens that
occurs right after that.  Make I<that> the last-matched group.  Loop
back to Step 2 until we think we've outputted enough.

4. But if the last-matched group from 2 occurred just that once in the
text, go back to step 1.

=back

Since the groups of characters or words (at least, when you look at
them as bits of text only group-size tokens long) are all taken from
the input text, you get somewhat natural-looking text -- as opposed to
what you'd get if you just randomly outputted single characters or
single words from the input text.

The process of applying a DissociatedPress algorithm to a bit
of text is called "dissociation".

=head1 PARAMETERS AND USAGE

To use this module after you've installed it, say "use
Games::Dissociate".  This imports the function C<dissociate> and the
procedure C<dissociate_filter>.

=over 4

=item dissociate($input, $group_size, $max)

The function C<dissociate> takes three parameters:

  $output = dissociate($input, $group_size, $max);

$input is the input string, hopefully containing a stretch of
(plaintext) text in a human language, encoded either in just plain
US-ASCII, or in a character-encoding your locale settings know about.
$output will be "dissociated text" (charmingly generated gibberish)
based on that input text.  (Note that output will contain no
line-breaks or tabs.  Yoy may wish, as C<dissociate_filter> does,
to pass the output thru Text::Wrap's C<wrap>.)

You'll get strange output if $input contains markup (HTML, LaTeX,
etc.), or is very short, or is not in a human language.

$group_size is the number of tokens (words or characters) that must be
in common between bits of text the dissociation algorithm skips
between.  A positive value means you want to dissociate by character,
with a group-size of that many characters (4 = 4 characters); a
negative value means you want to dissociate by word, with a group size
of that many words (-2 = 2 words).  I suggest values between -3 and 5;
I'm a fan of -2.  A $group_size value of 0 or 1 is invalid, and
currently causes C<dissociate> to use the default value of 2 (2
characters) instead.  A value of -1 is invalid, and currently causes
C<dissociate> to use the value of -2 (2 words) instead.  The
behavior/validity of $group_size values of 0, 1, or -1 may change in
future versions.

$max is a parameter used to control the maximum number of iterations
of C<dissociate>'s central loop -- it corresponds roughly to the
number of "chunks" of text you get back, where a chunk is N *
-$group_size words for negative values of $group_size, and N *
$group_size characters for positive values of $group_size.  $max must
be greater than 1.

If you need (!) more precise control over the size of the output text,
try setting set $max high and trim the output to size, and/or try
calling C<dissociate> multiple times until you get the amount of output
you want.  (But be sure to give up if C<dissociate> keeps returning
nullstring, as it will in some strange cases.)

C<dissociate> can also be called with the following syntaxes:

  dissociate($input, $group_size);
   # acts like max of 100

  dissociate($input);
   # acts like group size of 2 (characters) and max of 100

=item dissociate_filter()

=item dissociate_filter($group_size)

=item dissociate_filter($group_size, $max)

This library also provides the procedure C<dissociate_filter>, which
pulls input from "<>" (files specified on the command line, or STDIN),
and sends dissociated output to STDOUT.  It can be called with these
syntaxes:

  dissociate_filter($group_size, $max);

  dissociate_filter($group_size);
   # uses a default value for $max

  dissociate_filter();
   # uses a default value for $group_size and $max

These above-mentioned default values can come from command line
switches, if you make a script consisting of:

  #!/usr/local/bin/perl
  use Games::Dissociate;
  dissociate_filter;

and call that script, say, C<dissociate>, and call it as:

  dissociate -c5 -m200 < foo.txt

or

  dissociate -w2 -m70 foo.txt bar.txt | less

and so on.

To explain the switches:

C<-w[number]> specifies a by-word dissociation with that number of
words as the group size, C<-c[number]> specifies a by-character
dissociation with that number of characters as the group size,
C<-m[number]> specifies a default for $max.

If you don't specify a default for $group_size or $max, $group_size
defaults to 100 and $max defaults to 2 (characters).

=back

=head2 Efficiency Notes

This module has to search the input string by performing regexp
searches on it.  In the current version of this module, control over
compilation of regular expressions may not be not optimally efficient.
Perl 5.005 provides options to better control regexp compilation; once
Perl 5.005 is in wider use, I may come out with a new version of
Games::Dissociate requiring Perl 5.005 or later, using these new
regexp compilation control features.

If you feed this module a lot of text (over 50K, say), it will indeed
get very slow (notably with by-word dissociation), since that whole
chunk of text has to be searched over and over and over.

If you have an idea for making this module more efficient, feel free
to email it to me.

=head2 Internationalization Notes

When dealing with text in heavily inflected languages (like Finnish --
lots of unique word endings, frequently used), this module will
require longer input text to produce interesting results for by-word
dissociation, compared to relatively inflection-poor languages like
English.

For text written with no inter-word spacing (often the case with Thai,
for example), there's no way for this module to tell where the word
breaks are -- in such cases, use only the by-character mode.

The current version of this library assumes "/./" matches a single
character, for by-character dissociation; and, for by-word
dissociation, that "/\w+/" matches whole words and /\W+/ matches
non-word strings.  These are locale-dependent functions, and
Games::Dissociate has a "use locale" in it, hopefully triggering
correct behavior for your favorite locale, language, and
character-encoding.  Consult L<perllocale> and L<locale> for more
information on locales.

I I<have> found "use locale" to do unwelcome things (like
unceremoniously dumping core) on a few very strange, very old (and
otherwise barely-working) machines.  If this is a problem for you, or
if you don't plan to use locales, comment out the "use locale" in the
Games::Dissociate source code.

The treatment of locales and support for them may change in future
versions of this module, depending on how future Perl versions shape
up, particularly in their support of Unicode.

=head2 Randomness Notes

This library uses C<rand> extensively, but never calls C<srand>.  If
you're getting the same dissociated output all the time, then you're
using an old (pre-5.004) version of Perl that doesn't do implicit
randomness seeding -- just call "srand();", maybe right after you say
"use Games::Dissociate";

=head1 SEE ALSO

* Emacs's C<dissociate.el> (written circa 1985?).

=head1 COPYRIGHT

Copyright (c) 1998-2001, Sean M. Burke. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 REMINDER

It's just a toy.

=head1 AUTHOR

Current maintainer Avi Finkel C<avi@finkel.org>;  Original author Sean M. Burke <sburke@cpan.org>

=cut

