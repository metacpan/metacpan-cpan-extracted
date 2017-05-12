package Locale::Maketext::Fuzzy;
$Locale::Maketext::Fuzzy::VERSION = '0.11';

use 5.005;
use strict;
use Locale::Maketext;
use base 'Locale::Maketext';

sub override_maketext {
    my ( $class, $flag ) = @_;
    $class = ref($class) if ref($class);

    no strict 'refs';

    if ($flag) {
        *{"$class\::maketext"} = \&maketext_fuzzy;
    }
    elsif ( @_ >= 2 ) {
        delete ${"$class\::"}{maketext};
    }

    return ( defined &{"$class\::maketext"} ? 1 : 0 );
}

# Global cache of entries and their regexified forms
my %regex_cache;

sub maketext_fuzzy {
    my ( $handle, $phrase ) = splice( @_, 0, 2 );

    # An array of all lexicon hashrefs
    my @lexicons = @{ $handle->_lex_refs };

    # Try exact match if possible at all.
    foreach my $lex (@lexicons) {
        return $handle->SUPER::maketext( $phrase, @_ )
          if exists $lex->{$phrase};
    }

    # Keys are matched entries; values are arrayrefs of extracted params
    my %candidate;

    # Fuzzy match phase 1 -- extract all candidates
    foreach my $lex (@lexicons) {

        # We're not interested in non-bracketed entries, so ignore them
        foreach my $entry ( grep /(?:(?<!~)(?:~~)*)\[/, keys %{$lex} ) {
            # Skip entries which are _only_ brackets and whitespace.
            # The most value they could add is rearrangement, and that
            # is almost certainly incorrect.
            next if $entry =~ /^\s*(\[[^]]+\]\s*)+$/;

            my $re = ( $regex_cache{$entry} ||= [ _regexify($entry) ] );
            my @vars = ( $phrase =~ $re->[0] ) or next;
            $candidate{$entry} ||=
              ( @{ $re->[1] } ? [ @vars[ @{ $re->[1] } ] ] : \@vars );
        }
    }

    # Fail early if we cannot find anything that matches
    return $phrase unless %candidate;

    # Fuzzy match phase 2 -- select the best candidate
    $phrase = (
        sort {

            # For now, we just use a very crude heuristic: "Longer is better"
            length($b) <=> length($a)
              or $b cmp $a
          } keys %candidate
    )[0];

    return $handle->SUPER::maketext( $phrase, @{ $candidate{$phrase} }, @_ );
}

sub _regexify {
    my $text = quotemeta(shift);
    my @ords;

    $text =~ s{
	(				# capture into $1...
	    (?<!\\~)(?:\\~\\~)*		#   an even number of ~ characters
	)				#   (to be restored back)
	\\\[				# opening bracket

	(				# capture into $2...
	    (?:				#   any numbers of
		[^~\]]			#     ordinary non-] characters
		    |			#       or
		~\\?.			#     escaped characters
	    )*
	)
	\\\]				# closing bracket
    }{
	$1._paramify($2, \@ords)
    }egx;

    $text =~ s/\Q.*?\E$/.*/;
    return qr/^$text$/, \@ords;
}

sub _paramify {
    my ( $text, $ordref ) = @_;
    my $out = '(.*?)';
    my @choices = split( /\\,/, $text );

    if ( $choices[0] =~ /^(?:\w+|\\#|\\\*)$/ ) {

        # Do away with the function name
        shift @choices unless $choices[0] =~ /^_(?:\d+|\\\*)$/;

        # Build an alternate regex to weed out vars
        $out .= '(?:' . join(
            '|',
            sort {
                length($b) <=> length($a)    # longest first
              } map {
                /^_(?:(\d+)|\\\*)$/
                  ? do {
                    push @{$ordref}, ( $1 - 1 ) if defined $1;
                    '';
                  }
                  : $_                       # turn _1, _2, _*... into ''
              } @choices
        ) . ')';

        $out =~ s/\Q(?:)\E$//;
    }

    return $out;
}

1;

=head1 NAME

Locale::Maketext::Fuzzy - Maketext from already interpolated strings

=head1 SYNOPSIS

    package MyApp::L10N;
    use base 'Locale::Maketext::Fuzzy'; # instead of Locale::Maketext

    package MyApp::L10N::de;
    use base 'MyApp::L10N';
    our %Lexicon = (
	# Exact match should always be preferred if possible
	"0 camels were released."
	    => "Exact match",

	# Fuzzy match candidate
	"[quant,_1,camel was,camels were] released."
	    => "[quant,_1,Kamel wurde,Kamele wurden] freigegeben.",

	# This could also match fuzzily, but is less preferred
	"[_2] released[_1]"
	    => "[_1][_2] ist frei[_1]",
    );

    package main;
    my $lh = MyApp::L10N->get_handle('de');

    # All ->maketext calls below will become ->maketext_fuzzy instead
    $lh->override_maketext(1);

    # This prints "Exact match"
    print $lh->maketext('0 camels were released.');

    # "1 Kamel wurde freigegeben." -- quant() gets 1
    print $lh->maketext('1 camel was released.');

    # "2 Kamele wurden freigegeben." -- quant() gets 2
    print $lh->maketext('2 camels were released.');

    # "3 Kamele wurden freigegeben." -- parameters are ignored
    print $lh->maketext('3 released.');

    # "4 Kamele wurden freigegeben." -- normal usage
    print $lh->maketext('[*,_1,camel was,camels were] released.', 4);

    # "!Perl ist frei!" -- matches the broader one
    # Note that the sequence ([_2] before [_1]) is preserved
    print $lh->maketext('Perl released!');

=head1 DESCRIPTION

This module is a subclass of C<Locale::Maketext>, with additional
support for localizing messages that already contains interpolated
variables.

This is most useful when the messages are returned by external sources
-- for example, to match C<dir: command not found> against
C<[_1]: command not found>.

Of course, this module is also useful if you're simply too lazy
to use the

    $lh->maketext("[quant,_1,file,files] deleted.", $count);

syntax, but wish to write

    $lh->maketext_fuzzy("$count files deleted");

instead, and have the correct plural form figured out automatically.

If C<maketext_fuzzy> seems too long to type for you, this module
also provides a C<override_maketext> method to turn I<all> C<maketext>
calls into C<maketext_fuzzy> calls.

=head1 METHODS

=head2 $lh->maketext_fuzzy(I<key>[, I<parameters...>]);

That method takes exactly the same arguments as the C<maketext> method
of C<Locale::Maketext>.

If I<key> is found in lexicons, it is applied in the same way as
C<maketext>.  Otherwise, it looks at all lexicon entries that could
possibly yield I<key>, by turning C<[...]> sequences into C<(.*?)> and
match the resulting regular expression against I<key>.

Once it finds all candidate entries, the longest one replaces the
I<key> for the real C<maketext> call.  Variables matched by its bracket
sequences (C<$1>, C<$2>...) are placed before I<parameters>; the order
of variables in the matched entry are correctly preserved.

For example, if the matched entry in C<%Lexicon> is C<Test [_1]>,
this call:

    $fh->maketext_fuzzy("Test string", "param");

is equivalent to this:

    $fh->maketext("Test [_1]", "string", "param");

However, most of the time you won't need to supply I<parameters> to
a C<maketext_fuzzy> call, since all parameters are already interpolated
into the string.

=head2 $lh->override_maketext([I<flag>]);

If I<flag> is true, this accessor method turns C<$lh-E<gt>maketext>
into an alias for C<$lh-E<gt>maketext_fuzzy>, so all consecutive
C<maketext> calls in the C<$lh>'s packages are automatically fuzzy.
A false I<flag> restores the original behaviour.  If the flag is not
specified, returns the current status of override; the default is
0 (no overriding).

Note that this call only modifies the symbol table of the I<language
class> that C<$lh> belongs to, so other languages are not affected.
If you want to override all language handles in a certain application,
try this:

    MyApp::L10N->override_maketext(1);

=head1 CAVEATS

=over 4

=item *

The "longer is better" heuristic to determine the best match is
reasonably good, but could certainly be improved.

=item *

Currently, C<"[quant,_1,file] deleted"> won't match C<"3 files deleted">;
you'll have to write C<"[quant,_1,file,files] deleted"> instead, or
simply use C<"[_1] file deleted"> as the lexicon key and put the correct
plural form handling into the corresponding value.

=item *

When used in combination with C<Locale::Maketext::Lexicon>'s C<Tie>
backend, all keys would be iterated over each time a fuzzy match is
performed, and may cause serious speed penalty.  Patches welcome.

=back

=head1 SEE ALSO

L<Locale::Maketext>, L<Locale::Maketext::Lexicon>

=head1 HISTORY

This particular module was written to facilitate an I<auto-extraction>
layer for Slashcode's I<Template Toolkit> provider, based on
C<HTML::Parser> and C<Template::Parser>.  It would work like this:

    Input | <B>from the [% story.dept %] dept.</B>
    Output| <B>[%|loc( story.dept )%]from the [_1] dept.[%END%]</B>

Now, this layer suffers from the same linguistic problems as an
ordinary C<Msgcat> or C<Gettext> framework does -- what if we want
to make ordinals from C<[% story.dept %]> (i.e. C<from the 3rd dept.>),
or expand the C<dept.> to C<department> / C<departments>?

The same problem occurred in RT's web interface, where it had to
localize messages returned by external modules, which may already
contain interpolated variables, e.g. C<"Successfully deleted 7
ticket(s) in 'c:\temp'.">.

Since I didn't have the time to refactor C<DBI> and C<DBI::SearchBuilder>,
I devised a C<loc_match> method to pre-process their messages into one
of the I<candidate strings>, then applied the matched string to C<maketext>.

Afterwards, I realized that instead of preparing a set of candidate
strings, I could actually match against the original I<lexicon file>
(i.e. PO files via C<Locale::Maketext::Lexicon>).  This is how
C<Locale::Maketext::Fuzzy> was born.

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to Locale-Maketext-Fuzzy.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=cut
