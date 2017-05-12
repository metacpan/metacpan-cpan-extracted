package Emacs::Rep;
#                                doom@kzsu.stanford.edu
#                                15 May 2010
#                                 3 Jun 2012

=head1 NAME

Emacs::Rep - a find & replace engine for rep.pl and rep.el

=head1 SYNOPSIS

  use Emacs::Rep qw( do_finds_and_reps  parse_perl_substitutions );

   my $substitutions =>>'END_S';
      s/jerk/iconoclast/
      s/conniving/shrewd/
      s/(t)asteless/$1alented/i
  END_S

  my $find_replaces_aref =
    parse_perl_substitutions( \$substitutions );

  my $change_metatdata_aref =
        do_finds_and_reps( \$text, $find_replaces_aref );

=head1 DESCRIPTION

Emacs::Rep is a module that acts as a back-end for the rep.pl
script which in turn is used by the emacs library.  rep.el.

Emacs::Rep is a find and replace engine that can perform
multiple perl substitution commands (e.g. s///g) on a given
file, recording all metadata about each change so that an an
external program (such as emacs) can interactively display
and control the changes.

The end user isn't expected to need to use these routines
directly.

An application programmer might use these routines to add
support to an interactive front-end (Emacs or otherwise).

=head2 EXPORT

None by default.  Any of the following may be requested (or all
with the ':all' tag).

=over

=cut

use 5.008;
use strict;
use warnings;
my $DEBUG = 0;
use Carp;
use Data::Dumper;
use PPI;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [
  qw(
      parse_perl_substitutions
      do_finds_and_reps

      accumulate_find_reps
      check_versions
    ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(  );
our $VERSION = '1.00';  # TODO manually sync-up rep.pl and rep.el versions

=item parse_perl_substitutions

Breaks down a set of perl substitution command (i.e. "s///;",
"s{}{};", etc.)  into it's main components (the find pattern
and the replace expression).  It returns this in an an array
of arrays data structure (which is the form used by L<do_finds_and_args>).

Takes one argument, a scalar reference to a block of text
containing one or more perl substitution commands, in any
form (PPI is used internally to parse this).

The more elaborate "s{}{}xmsg;" is fine, as well as "s///g;".

End of line comments (after the closing semicolon) beginning with a "#",
are allowed, as are embedded comments inside the find pattern
if the /x modifier is in use.

Example usage:

my $substitutions =>>'END_S';
  s/pointy-haired boss/esteemed leader/g;
  s/death spiral/minor adjustment/g;
END_S

my $find_replaces_aref =
  parse_perl_substitutions( \$substitutions );

Where the returned data should look like:

   [ ['pointy-haired boss', 'esteemed leader'],
     ['death spiral',       'minor adjustment'],
   ]

Any trailing modifiers are automatically prefixed to the
find_pattern, using the (? ... ) notation, *except* for /g
and /e.

For purposes of L<do_finds_and_reps> /e is always ignored
(as of this writing), and /g is always assumed, irrespective
of whether it was added explicitly.

=cut

sub parse_perl_substitutions {
  my $reps_text_ref = shift;
  my $Document = PPI::Document->new( $reps_text_ref );
  my $s_aref = $Document->find('PPI::Token::Regexp::Substitute');
  my @find_reps;
  foreach my $s_obj (@{ $s_aref }) {
    my $find      = $s_obj->get_match_string;
    my $rep       = $s_obj->get_substitute_string;
    my $modifiers = $s_obj->get_modifiers; # href
    my @delims    = $s_obj->get_delimiters;

    my $raw_mods = join '', keys %{ $modifiers };

    accumulate_find_reps( \@find_reps, $find, $rep, $raw_mods );
  }
  \@find_reps;
}

=item accumulate_find_reps

For internal use.  Example usage:

 accumulate_find_reps( \@find_reps, $find, $rep, $raw_mods );

=cut

sub accumulate_find_reps {
  my $find_reps_aref = shift;
  my $find           = shift;
  my $rep            = shift;
  my $raw_mods       = shift;

  if ($raw_mods) {
    # The modifiers we care about (screening out spurious g or e or ;)
    my @mods = qw( x m s i );
    my $mods = '';
    foreach my $m (@mods) {
      if ( $raw_mods =~ qr{$m}x ) {
        $mods .= $m;
      }
    }
    # modify $find to incorporate the modifiers internally
    $find = "(?$mods)" . $find if $mods;
  }

  push @{ $find_reps_aref }, [ $find, $rep ];
}

=item do_finds_and_reps

Does a series of finds and replaces on some text and
returns the beginning and end points of each of the
modfied regions, along with some other information about
the matches.

Takes two arguments:

(1) The text to be modified, usually as a reference, though a scalar is okay
(2) A series of find and replace pairs in the form
    of an aref of arefs, e.g.

  $find_replaces_aref =
   [ ['jerk',            'iconoclast'],
     ['conniving',       'shrewd'].
     ['(?i)(t)asteless', '$1alented'].
   ]:

(See L<parse_perl_substitutions>.)

Example usage:

$locations_aref =
   do_finds_and_reps( \$text, $find_replaces_aref );

The returned change metadata is an aref of arefs of hrefs;
an array of passes with an entry for each substitution pair,
an an array of changes made by each pass.  The href has
keys: 'beg', 'delta', 'orig', 'rep'.

The fields 'orig' and 'rep' contain the modified string, before
and after the change.

'delta' is the change in length due to the change.

'beg' is the beginning of the region that was modified, an
integer counting from the start of the file, where the first
character is 1.

This numbering does not change while a s///g is in progress,
even if it is changing the length of the strings.
And further, these change locations are recorded *during* each pass,
which means that later passes throw off the numbering.

In practice, for the rep.el application, we apply this data
on the emacs side in inverse order, so that the numbering is
correct in the context we use it.

Note, error messages are routed to stdout, labeled with the
prefix "Problem:". The elisp call shell-command-to-string
merges stdout and stderr, but we use the 'Problem' prefix to
spot error messages

=cut

sub do_finds_and_reps {
  my $arg      = shift;
  my $text_ref = ref( $arg ) ? $arg : \$arg;
  my $find_replaces = shift; # aref of aref: a series of pairs

  my @change_metadata;
  eval {
    for ( my $pass = 0; $pass <= $#{ $find_replaces }; $pass++ ) {
      my ($find_pat, $replace) = @{ $find_replaces->[ $pass ] };
      my @pass; # change_metadata for this pass
      ${ $text_ref } =~
        s{$find_pat}
         {
           my $new = eval "return qq{$replace}";
           my $l1 = length( $& );
           my $l2 = length( $new );
           my $delta = $l2 - $l1;
           # pos points at the *start* of the match (inside of a s///eg)
           # And char numbering fixed at the start of the s///ge run
           my $p = pos( ${ $text_ref } ) + 1;
           my $beg = $p;

           # preserving some context
           my $post = substr( $',  0, 10 );  # Note: no BOF/EOF errors
           my $pre  = substr( $`, -10 );

           push @pass, {
                         beg   => $beg,
                         delta => $delta,
                         orig  => $&,
                         rep   => $new,
                       };
           $new
         }ge;
      push @change_metadata, \@pass;
    }
  };
  if ($@) {
    # Send error message to STDOUT so that it won't mess up test output.
    # (and anyway, the elisp call shell-command-to-string merges in STDERR)
    #
    # The elisp function rep-run-perl-substitutions uses prefix "Problem".
    # to spot error messages
    print "Problem: $@\n";
    # roll-back
    @change_metadata = ();
  }

  return \@change_metadata; # array of array of hrefs (keys: beg, end, delta, orig, etc)
}


=item check_versions

Verify that all three pieces of the system have the same version:
the *.pl, *.pm and *.el.

The elisp code is expected to run this command string with
it's own version number:

   perl rep.pl --check_versions="0.08"

rep.pl then runs this check_versions routine, passing along the
elisp version and the rep.pl version number:

Example usage:

  check_versions( $elisp_version, $script_version );

This compares those two versions with the module's version,
and warns if they're not all the same.

=cut

sub check_versions {
  my $elisp_version  = shift;
  my $script_version = shift;
  my $module_version = $VERSION;

  my $mess;
  if ( not(
           ($elisp_version  == $script_version) &&
           ($script_version == $module_version) ) ) {
    $mess = "Warning: all three versions should match: \n" .
      "rep.el: $elisp_version \n" .
      "rep.pl: $script_version \n" .
      "Rep.pm: $module_version \n";
    return $mess;
  } else {
    return $module_version;
  }
}



1;

=back

=head1 SEE ALSO

The web page for this project is:

  http://obsidianrook.com/rep

The code is available on github (as well as on CPAN):

  http://github.com/doomvox/rep

Emacs::Rep is the back-end for the script rep.pl which
in turn is the back-end for the emacs lisp code rep.el.

If rep.el is not installed, look in the "elisp" sub-directory
of this CPAN package.

A good discussion forum for projects such as this is:

  http://groups.google.com/group/emacs-perl-intersection

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010,2012 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 BUGS

None reported... yet.

=cut
