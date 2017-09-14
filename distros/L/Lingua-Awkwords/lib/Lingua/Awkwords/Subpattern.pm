# -*- Perl -*-
#
# subpatterns are named A-Z and offer short-hand notation for e.g. V =>
# a/e/i/o/u (or instead a reference to some other parse tree)

package Lingua::Awkwords::Subpattern;

use strict;
use warnings;
use Carp qw(confess croak);
use Moo;
use namespace::clean;

our $VERSION = '0.05';

# these defaults set from what the online version does at
# http://akana.conlang.org/tools/awkwords/
my %patterns = (
    C => [qw/p t k s m n/],
    N => [qw/m n/],
    V => [qw/a i u/],
);

has pattern => (
    is      => 'rw',
    trigger => sub {
        my ( $self, $pat ) = @_;
        die "subpattern $pat does not exist" unless exists $patterns{$pat};
        $self->_set_target( $patterns{$pat} );
    },
);
has target => ( is => 'rwp', );

########################################################################
#
# METHODS

sub get_patterns {
    return %patterns;
}

sub is_pattern {
    my ( undef, $pat ) = @_;
    return exists $patterns{$pat};
}

sub render {
    my ($self) = @_;

    my $ret;
    my $target = $self->target;
    my $type   = ref $target;

    # this complication allows for subpatterns to point at other parse
    # trees instead of just simple terminal strings (yes, you could
    # create loops where a ->render points to itself (don't do that))
    #
    # NOTE walk sub must be kept in sync with this logic
    if ( !$type ) {
        $ret = $target;
    } else {
        if ( $type eq 'ARRAY' ) {
            # do not need Math::Random::Discrete here as the weights are
            # always equal; for weighted instead write that unit out
            # manually via [a*2/e/i/o/u] or such
            $ret = @{$target}[ rand @$target ] // '';
        } else {
            $ret = $target->render;
        }
    }
    return $ret;
}

sub set_patterns {
    my $class_or_self = shift;
    # TODO error checking here may be beneficial if callers are in the
    # habit of passing in data that blows up on ->render or ->walk
    %patterns = ( %patterns, @_ );
    return $class_or_self;
}

sub update_pattern {
    my $class_or_self = shift;
    my $pattern       = shift;

    # TODO more error checking here may be beneficial if callers are in
    # the habit of passing in data that blows up on ->render
    croak "update needs a pattern and a list of values\n" unless @_;
    croak "value must be defined" if !defined $_[0];

    # NOTE arrayref as single argument is saved without making a copy of
    # the contents; this will allow the caller to potentially change
    # that ref and thus influence what is stored in patterns after this
    # update_pattern call
    $patterns{$pattern} = @_ == 1 ? $_[0] : [@_];

    return $class_or_self;
}

sub walk {
    my ( $self, $callback ) = @_;

    $callback->($self);

    my $target = $self->target;
    my $type   = ref $target;

    # NOTE this logic must be kept in sync with render sub
    if ( $type and $type ne 'ARRAY' ) {
        $target->walk($callback);
    }
    return;
}

1;
__END__

=head1 NAME

Lingua::Awkwords::Subpattern - implements named subpatterns

=head1 SYNOPSIS

  use feature qw(say);
  use Lingua::Awkwords;
  use Lingua::Awkwords::Subpattern;

  # pick-one-of-these patterns (equal weights)
  Lingua::Awkwords::Subpattern->set_patterns(
      C => [qw/p t k s m n/],
      N => [qw/m n/],
      V => [qw/a i u/],
  );

  my $triphthong = Lingua::Awkwords->new( pattern => q{ VVV } );
  say $triphthong->render;

  # patterns can also point to parse trees
  Lingua::Awkwords::Subpattern->update_pattern(
      T => $triphthong
  );

  my $tritriphthong = Lingua::Awkwords->new( pattern => q{ TTT } );
  say $tritriphthong->render;

=head1 DESCRIPTION

Subpatterns are named (with the ASCII letters C<A-Z>) elements of an
awkwords pattern that expand out to some list of equally weighted
choices, or existing parse tree objects. That is, C<V> in a I<pattern>
can be a shorthand notation for

  [a/e/i/o/u]

See the source code for what patterns are defined by default, or use
B<set_patterns> or B<update_pattern> to change the values.

=head1 ATTRIBUTES

=over 4

=item I<pattern>

The pattern this object represents. Mandatory. Typically should be an
ASCII letter in the C<A-Z> range and typically should be set via the
B<new> method.

=item I<target>

Array reference or object the I<pattern> points to. Prior to 0.03 this
did not exist, and the target would be looked up from the patterns
each time.

=back

=head1 METHODS

=over 4

=item B<get_patterns>

Returns the presently set (global) patterns and their corresponding
values as a list of keys and values.

=item B<is_pattern> I<pattern>

Returns a boolean indicating whether I<pattern> is an existing
pattern or not.

=item B<new>

Constructor. A I<pattern> should ideally be supplied. Will throw an
error if the I<pattern> does not exist in the global patterns list.

  Lingua::Awkwords::Subpattern->new( pattern => 'V' )

=item B<render>

Returns a random item from the list of choices, or calls B<render> if
the I<target> is a reference of the not-ARRAY kind.

=item B<set_patterns> I<list-of-patterns-and-choices>

Resets I<all> the choices. These changes are global to a process. For
example for the Toki Pona language one might set C<C> for consonants and
C<V> for vowels via

  Lingua::Awkwords::Subpattern->set_patterns(
      C => [qw/j k l m n p s t w/],
      V => [qw/a e i o u/],
  );

Choices can either be simple string values or an object ideally with a
B<render> method. L<Lingua::Awkwords/COMPLICATIONS> has an example of
the later form.

=item B<update_pattern> I<pattern> I<choices>

Updates the choices for the given I<pattern>. This happens globally in
a process.

Note that array references are treated differently than lists of values;

  my $nnmm = [qw/n m/];
  Lingua::Awkwords::Subpattern->update_pattern( N => $nnmm );

allows the array reference C<$nnmm> to be changed by the caller
(thus affecting future I<pattern> of future objects created in this
class), while

  Lingua::Awkwords::Subpattern->update_pattern( N => @$nnmm );

does not allow the caller to then change anything as instead a copy of
the list of choices has been made.

=item B<walk> I<callback>

Calls the I<callback> function with itself as the argument, then if the
I<target> is an object calls B<walk> on that object.

=back

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-lingua-awkwords at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-Awkwords>.

Patches might best be applied towards:

L<https://github.com/thrig/Lingua-Awkwords>

=head2 Known Issues

There can only be 26 named subpatterns and these are global to the
process. It may be beneficial to (optionally?) make them instance
specific somehow, though a workaround for that is to incrementally build
up a complicated parse tree from one or more other parse trees.

=head1 SEE ALSO

L<Lingua::Awkwords>, L<Lingua::Awkwords::Parser>

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
