# -*- Perl -*-
#
# randomly generates outputs from a given pattern

package Lingua::Awkwords;

use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw/&percentize &set_filter &weights2str &weights_from/;

use Carp qw(croak);
use Lingua::Awkwords::Parser;
use Moo;
use namespace::clean;

our $VERSION = '0.06';

has pattern => (
    is      => 'rw',
    trigger => sub {
        my ( $self, $pat ) = @_;
        $self->_set_tree( Lingua::Awkwords::Parser->new->from_string($pat) );
    },
);
has tree => ( is => 'rwp' );

########################################################################
#
# FUNCTIONS
#
# TODO these probably should go in a ::Util module?

# utility routine that makes percentages of the presumably numeric
# values of the given hash reference
sub percentize {
    my ($href) = @_;
    my $sum    = 0;
    my $min    = ~0;
    for my $v ( values %$href ) {
        $sum += $v;
        $min = $v if $v < $min;
    }
    croak "sum of values cannot be 0" if $sum == 0;
    for my $v ( values %$href ) {
        $v = $v / $sum * 100;
    }
}

# utility routine for use with ->walk
sub set_filter {
    my $filter = shift;
    return sub {
        my $self = shift;
        $self->filter_with($filter) if $self->can('filter_with');
    };
}

sub weights2str {
    my ($href) = @_;
    join '/', map { join '*', $_, $href->{$_} } sort keys %$href;
}

sub weights_from {
    my ($input) = @_;

    my $type = ref $input;
    my $fh;

    if ($type eq '') {
        open $fh, '<', \$input;
    } elsif ($type eq 'GLOB') {
        $fh = $input;
    } else {
        croak "unknown input type";
    }

    my ( %first, %mid, %last, %all );

    while (readline $fh) {
        chomp;
      LOOP: {
            redo LOOP if /\G\s+/cg;
            # various \b{...} forms detailed in perlrebackslash may be
            # better for word boundaries though require perl 5.22 or up
            if (m/\G\b(.)/cg) {
                $first{$1}++;
                $all{$1}++;
                redo LOOP;
            }
            if (m/\G(.)\b/cg) {
                $last{$1}++;
                $all{$1}++;
                redo LOOP;
            }
            if (m/\G\B(.)/cg) {
                $mid{$1}++;
                $all{$1}++;
                redo LOOP;
            }
        }
    }

    return \%first, \%mid, \%last, \%all;
}

########################################################################
#
# METHODS

# avoids need to say
#   use Lingua::Awkwords::Parser;
#   ... = Lingua::Awkwords::Parser->new->from_string(q{ ...
# in the calling code
sub parse_string {
    my ( $self_or_class, $str ) = @_;
    return Lingua::Awkwords::Parser->new->from_string($str);
}

sub render {
    my ($self) = @_;
    my $tree = $self->tree;
    croak "no pattern supplied" if !defined $tree;
    return $tree->render;
}

sub walk {
    my ( $self, $callback ) = @_;
    my $tree = $self->tree;
    croak "no pattern supplied" if !defined $tree;
    $tree->walk($callback);
    return;
}

1;
__END__

=head1 NAME

Lingua::Awkwords - randomly generates outputs from a given pattern

=head1 SYNOPSIS

  use feature qw(say);
  use Lingua::Awkwords;
  use Lingua::Awkwords::Subpattern;

  # V is a pre-defined subpattern, ^ filters out aa from the list
  # of two vowels that the two VV generate
  my $la = Lingua::Awkwords->new( pattern => q{ [VV]^aa } );

  say $la->render for 1..10;

  # define our own C, V
  Lingua::Awkwords::Subpattern->set_patterns(
      C => [qw/j k l m n p s t w/],
      V => [qw/a e i o u/],
  );
  # and a pattern somewhat suitable for Toki Pona...
  $la->pattern(q{
      [a/*2]
      (CV*5)^ji^ti^wo^wu
      (CV*2)^ji^ti^wo^wu
      [CV/*2]^ji^ti^wo^wu
      [n/*5]
  });

  say $la->render for 1..10;

=head1 DESCRIPTION

This is a Perl implementation of

http://akana.conlang.org/tools/awkwords/

though is not an exact replica of that parser;

http://akana.conlang.org/tools/awkwords/help.html

details the format that this code is based on. Briefly,

=head2 SYNTAX

=over 4

=item I<[]> or I<()>

Denote a unit or group; they are identical except that C<(a)> is
equivalent to C<[a/]>--that is, it represents the possibility of
generating the empty string in addition to any other terms supplied.

Units can be nested recursively. There is an implicit unit at the top
level of the I<pattern>.

=item I</>

Introduces a choice within a unit; without this C<[Vx]> would generate
whatever C<V> represents (a list of vowels by default) followed by the
letter C<x> while C<[V/x]> by contrast generates only a vowel I<or> the
letter C<x>.

=item I<*>

The asterisk followed by an integer in the range C<1..INT_MAX> weights
the current term of the alternation, if any. That is, while C<[a/]>
generates each term with equal probability, C<[a/*2]> would generate the
empty string at twice the probability of the letter C<a>.

=item I<^>

The caret introduces a filter that must follow a unit (there is an
implicit unit at the top level of a I<pattern>). An example would be
C<[VV]^aa> or the equivalent C<VV^aa> that (by default) generates two
vowels, but replaces C<aa> with the empty string. More than one filter
may be specified.

=item I<A-Z>

Capital ASCII letters denote subpatterns; several of these are set by
default. See L<Lingua::Awkwords::Subpattern> for how to customize them.
C<V> for example is by default equivalent to the more verbose C<[a/i/u]>.

=item I<">

Use double quotes to denote a quoted string; this prevents other
characters (besides C<"> itself) from being interpreted as some non-
string value.

=item I<anything-else>

Anything else not otherwise accounted for above is treated as part of a
string, so C<["abc"/abc]> generates either the string C<abc> or the
string C<abc>, as this is two ways of saying the same thing.

=back

=head1 ATTRIBUTES

=over 4

=item I<pattern>

Awkword pattern. Without this supplied any call to B<render> will throw
an exception.

=item I<tree>

Where the parse tree is stored.

=back

=head1 FUNCTIONS

These can be called as C<Lingua::Awkwords::set_filter> or can be
imported via

  use Lingua::Awkwords qw(weights2str weights_from);

=over 4

=item B<percentize> I<hashref>

Modifies the values of the given I<hashref> to be percentages of the sum
of the values. Will B<croak> if sum is 0. Use this to help compare
B<weights_from> different corpus.

=item B<set_filter> I<filter-value>

Utility routine for use with B<walk>. Returns a subroutine that sets the
I<filter_with> attribute to the given value.

  $la->walk( Lingua::Awkwords::set_filter('X') );

=item B<weights2str> I<hash-reference>

Constructs an awkwords choice string from a given I<hash-reference> of
values and weights, e.g.

  use Lingua::Awkwords qw(weights2str weights_from);

  weights2str( ( weights_from("toki sin li toki pona") )[-1] )

will return a weight string of

  a*1/i*4/k*2/l*1/n*2/o*3/p*1/s*1/t*2

that can then be used as a I<pattern> for this module.

=item B<weights_from> I<string-or-filehandle>

Parses the frequency of characters appearing in the input string or
filehandle, and returns four hash references, I<first>, I<mid>, I<last>
and I<all> which contain the character counts of the first letters of
the "words" in the input, characters that appear in the middle, end, and
a tally of all three of these positions together.

"words" is used in scare quotes because there is "no generally accepted
and completely satisfactory definition of what constitutes a word"
(Philip Durkin. "The Oxford Guide to Etymology". p.37) and because
instead syllables could be fed in and then patterns generated using
those syllable-specific weights.

=back

=head1 METHODS

=over 4

=item B<new>

Constructor. Typically this should be passed a I<pattern> argument.

=item B<parse_string> I<pattern>

Returns the parse tree of the given I<pattern> without setting the I<tree>
attribute. L</COMPLICATIONS> shows one use for this.

=item B<render>

Returns a string render of the awkword I<pattern>. This may be the empty
string if filters have removed all the text.

=item B<walk> I<callback>

Provides a means to recurse through the parse tree, where every object
in the tree will call the I<callback> with C<$self> as the sole
argument, and then if necessary iterate through all of the possibilities
contained by itself calling B<walk> on each of those.

=back

=head1 COMPLICATIONS

More complicated structures can be built by attaching parse trees to
subpatterns. For example, Toki Pona could be extended to allow optional
diphthongs (mostly in the second syllable) via

  use feature qw(say);
  use Lingua::Awkwords::Subpattern;
  use Lingua::Awkwords;
  
  my $cv  = Lingua::Awkwords->parse_string(q{
      CV^ji^ti^wo^wu
  }); 
  my $cvv = Lingua::Awkwords->parse_string(q{
      CVV^ji^ti^wo^wu^aa^ee^ii^oo^uu
  });

  Lingua::Awkwords::Subpattern->set_patterns(
      A => $cv,
      B => $cvv,
      C => [qw/j k l m n p s t w/],
      V => [qw/a e i o u/],
  );

  my $tree = Lingua::Awkwords->new( pattern => q{
      [ a[B/BA/BAA/A/AA/AAA] / [AB/ABA/ABAA/A/AA/AAA] ] [n/*5]
  });

  say join ' ', map { $tree->render } 1 .. 10;

The default filter of the empty string can be problematical, as one
may not know whether a filter has been applied to the result, or the
word may be filtered into an incorrect form. Consult the C<eg/>
directory of this module's distribution for example code that
customizes the filter value.

Code that makes use of non-ASCII encodings may need appropriate settings
made, e.g. to use the locale for input and output and to allow UTF-8 in
the program text.

  use open IO  => ':locale';
  use utf8;

  Lingua::Awkwords::Subpattern->set_patterns(
      S => [qw/... UTF-8 data here .../],
  );

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-lingua-awkwords at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-Awkwords>.

Patches might best be applied towards:

L<https://github.com/thrig/Lingua-Awkwords>

=head2 Known Issues

There are various incompatibilities with the original version of the
code; these are detailed in the parser module as they concern how e.g.
weights are parsed.

See also the "Known Issues" section in all the other modules in this
distribution.

=head1 SEE ALSO

L<Lingua::Awkwords::ListOf>, L<Lingua::Awkwords::OneOf>,
L<Lingua::Awkwords::Parser>, L<Lingua::Awkwords::String>,
L<Lingua::Awkwords::Subpattern>

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
