# -*- Perl -*-
#
# randomly generates outputs from a given pattern

package Lingua::Awkwords;

use strict;
use warnings;

use Carp qw(croak);
use Lingua::Awkwords::Parser;
use Moo;
use namespace::clean;

our $VERSION = '0.04';

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
# METHODS

# avoids need to say
#   use Lingua::Awkwords::Parser;
#   ... = Lingua::Awkwords::Parser->new->from_string(q{ ...
# in the calling code
sub parse_string {
    my ($self_or_class, $str) = @_;
    return Lingua::Awkwords::Parser->new->from_string( $str );
}

sub render {
    my ($self) = @_;
    my $tree = $self->tree;
    croak "no pattern supplied" if !defined $tree;
    return $tree->render;
}

sub walk {
    my ($self, $callback) = @_;
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

The asterisk followed by an integer in the range C<1..128> inclusive
weights the current term of the alternation, if any. That is, while
C<[a/]> generates each term with equal probability, C<[a/*2]> would
generate the empty string at twice the probability of the letter C<a>.

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

The default filter of the empty string can be problematical, as one may
not know whether a filter has been applied to the result, or the word
may be filtered into an incorrect form. The above trees with filters can
be modified as follows

  $tree->walk( set_filter('X') );

  # more or less the equivalent of a let-over-lambda in LISP
  sub set_filter {
      my $filter = shift;
      return sub {
          my $self = shift;
          $self->filter_with($filter) if $self->can('filter_with');
      };
  }

to instead replace filtered values with C<X> and then enough words
generated minus those filtered via

  my @words;
  while (1) {
      my $possible = $tree->render;
      next if $possible =~ m/X/;
      push @words, $possible;
      last if @words >= 10;
  }
  say join ' ', @words;

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
