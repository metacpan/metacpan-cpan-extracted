package Iterator::Flex::Gather;

# ABSTRACT: Gather Iterator Class

use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.28';

use Iterator::Flex::Factory;
use Iterator::Flex::Utils qw[ THROW STATE EXHAUSTION :IterAttrs :IterStates ];
use Ref::Util;
use parent 'Iterator::Flex::Base';

use Iterator::Flex::Gather::Constants ':all';


use namespace::clean;






















































































































































sub new ( $class, $code, $iterable, $pars = {} ) {

    $class->_throw( parameter => q{'code' parameter is not a coderef} )
      unless Ref::Util::is_coderef( $code );

    my %pars = $pars->%*;

    my %state = (
        code                => $code,
        cycle_on_exhaustion => delete( $pars{cycle_on_exhaustion} ) // GATHER_CYCLE_STOP,
        src                 => $iterable,
    );

    $class->_throw( parameter => q{'cycle_on_exhaustion': illegal value} )
      if defined $pars{cycle_on_exhaustion}
      and $pars{cycle_on_exhaustion} != GATHER_CYCLE_CHOOSE
      and !$pars{cycle_on_exhaustion} & ( GATHER_CYCLE_STOP | GATHER_CYCLE_ABORT );

    $class->SUPER::new( \%state, \%pars );
}


sub construct ( $class, $state ) {

    $class->_throw( parameter => q{'state' parameter must be a HASH reference} )
      unless Ref::Util::is_hashref( $state );

    my ( $code, $src, $cycle_on_exhaustion ) = @{$state}{qw[ code src cycle_on_exhaustion ]};

    $src
      = Iterator::Flex::Factory->to_iterator( $src, { ( +EXHAUSTION ) => THROW } );

    my $self;

    # cached value if current element should be in
    # next cycle
    my $has_cache = !!0;
    my $cache;

    my $iterator_state;

    # This iterator may have to delay signalling exhaustion for one cycle if the
    # input iterator is exhausted, and it needs to return the last group of elements.
    # exhaustion.
    my $next_is_exhausted = !!0;

    return {
        ( +_NAME ) => 'igather',

        ( +_SELF ) => \$self,

        ( +STATE ) => \$iterator_state,

        ( +NEXT ) => sub {
            return $self->signal_exhaustion
              if $iterator_state == IterState_EXHAUSTED || $next_is_exhausted;

            my $cycle;
            my @gathered;
            my $ret = eval {
                while ( 1 ) {

                    my $rv = $has_cache ? $cache : $src->();
                    $has_cache = !!0;

                    local $_ = $rv;
                    my $result = $code->( \@gathered, GATHER_GATHERING );
                    $cycle = $result & GATHER_CYCLE_MASK;

                    $class->_throw( parameter => 'cycle action (continue, stop, abort, restart) was not specified' )
                      unless $cycle;

                    if ( ( $result & GATHER_ELEMENT_MASK ) == GATHER_ELEMENT_INCLUDE ) {
                        push @gathered, $rv;
                    }
                    elsif ( ( $result & GATHER_ELEMENT_MASK ) == GATHER_ELEMENT_CACHE ) {
                        $class->_throw( parameter =>
                              'inconsistent return: element action GATHER_ELEMENT_CACHE requires cycle action GATHER_CYCLE_STOP'
                        ) unless $cycle & GATHER_CYCLE_RESTART;
                        $cache     = $rv;
                        $has_cache = !!1;
                    }

                    last if $cycle & ( GATHER_CYCLE_RESTART | GATHER_CYCLE_STOP | GATHER_CYCLE_ABORT );
                }
                1;
            };
            if ( !$ret && length $@ ) {

                die $@
                  unless Ref::Util::is_blessed_ref( $@ )
                  && $@->isa( 'Iterator::Flex::Failure::Exhausted' );

                local $_ = undef;
                my $result
                  = $cycle_on_exhaustion == GATHER_CYCLE_CHOOSE
                  ? $code->( \@gathered, GATHER_SRC_EXHAUSTED )
                  : $cycle_on_exhaustion;
                return $self->signal_exhaustion
                  if ( $result & GATHER_CYCLE_ABORT )
                  || ( $result & GATHER_CYCLE_STOP && !@gathered );

                $next_is_exhausted = !!1;
            }

            return \@gathered;
        },
        (
            map { ( ( +RESET ) => $_, ( +REWIND ) => $_, ) } sub {
                $next_is_exhausted = $has_cache = !!0;
            },
        ),
        ( +_DEPENDS ) => $src,
    };
}

__PACKAGE__->_add_roles( qw[
      State::Closure
      Next::ClosedSelf
      Rewind::Closure
      Reset::Closure
      Current::Closure
] );

1;

#
# This file is part of Iterator-Flex
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Iterator::Flex::Gather - Gather Iterator Class

=head1 VERSION

version 0.28

=head1 METHODS

=head2 new

  use Iterator::Flex::Gather::Constants ':all';

  $iterator = Ierator::Flex::Gather->new( $coderef, $iterable, ?\%pars );

Returns an iterator which accumulates elements returned by
C<$iterable> based upon the return result of $coderef.  Gathered items
are returned as an arrayref.

C<$iterable> is converted into an iterator via
L<Iterator::Flex::Factory/to_iterator> if required.

C<$coderef> is called with the next item from iterable in the C<$_>
variable, and two parameters; the first is an arrayref containing the
gathered items, the second is a flag indicating whether the coderef is
called while gathering items (C<GATHER_GATHERING>)or after the source
has been exhausted (C<GATHER_SRC_EXHAUSTED>).

It should return the binary AND of two result codes.

The first result code indicates whether the the element should be
gathered, and must be one of

=over

=item *

C<GATHER_ELEMENT_INCLUDE>

The element is gathered.

=item *

C<GATHER_ELEMENT_EXCLUDE>

The element is discarded.

=item *

C<GATHER_ELEMENT_CACHE>

The element is neither gathered, nor discarded, but is cached, and it
is used instead of calling C<$iterable> for the next element This is
only of use when a cycle is restarted due to a difference in element
values.  See L</EXAMPLES/Gather into groups based on the value of a
key> for an example on how to use this.

This may only be used in conjunction with L</GATHER_CYCLE_RESTART>; an
exception is thrown otherwise.

=back

The second indicates whether the gathering cycle should stop and if
so, whether it should be restarted. It must be one of

=over

=item *

C<GATHER_CYCLE_CONTINUE>

Continue gathering.

=item *

C<GATHER_CYCLE_RESTART>

Stop gathering, and return the gathered items.  The next time the
iterator is invoked, it will begin a new cycle.

=item *

C<GATHER_CYCLE_STOP>

Stop gathering, and return the gathered items.
The next time the iterator is invoked, it will signal exhaustion.

=item *

C<GATHER_CYCLE_ABORT>

Stop gathering, and signal exhaustion.  Any gathered items are discarded.

=back

The optional C<%pars> hash may contain standard L<signal
parameters|Iterator::Flex::Manual::Overview/Signal Parameters> as well
as the following model parameters:

=over

=item *

cycle_on_exhaustion

When the C<$iterable> signals exhaustion, the gather iterator most
likely will have gathered elements which have not yet been returned.

The L</cycle_on_exhaustion> parameter may be used to specify how to
handle that case.

=over

=item *

C<GATHER_CYCLE_STOP>

If any items have been gathered and not returned, they will be
returned and the gather iterator will signal exhaustion when next invoked.

If there are no items to return, the gather iterator will signal exhaustion.

This is the default.

=item *

C<GATHER_CYCLE_ABORT>

The gather iterator will signal exhaustion, and any gathered items will be lost.

=item *

C<GATHER_CYCLE_CHOOSE>

Call C<$coderef> one last time, with C<$state> set to C<GATHER_SRC_EXHAUSTED>.
C<$coderef> should return either B<GATHER_CYCLE_STOP> or C<GATHER_CYCLE_ABORT>.

=back

=back

The iterator supports the following capabilities:

=over

=item next

=item reset

=item rewind

=back

=head1 INTERNALS

=head1 EXAMPLES

=head2 Gather only even numbers

  sub ( $gathered, $state ) {
      return GATHER_CYCLE_CONTINUE | (
          $_ % 2
          ? GATHER_ELEMENT_EXCLUDE
          : GATHER_ELEMENT_INCLUDE
      );
    }

=head2 Batch into groups of 10 elements

Consider using L<Iterator::Flex::Chunk>.

=head3 Add the current element to the gathered list

  sub ( $gathered, $state ) {
      return GATHER_ELEMENT_INCLUDE
        | ( $gathered->@* == (10 - 1) ? GATHER_CYCLE_RESTART : GATHER_CYCLE_CONTINUE );
  }

=head3 Save the current element for the next gather

  sub ( $gathered, $state ) {
      return ( $gathered->@* == 10 )
        ? GATHER_ELEMENT_CACHE | GATHER_CYCLE_RESTART
        : GATHER_ELEMENT_INCLUDE | GATHER_CYCLE_CONTINUE;
    }

=head2 Gather into groups based on the value of a key

Need to cache the current value if it belongs in the next group.
Input elements are hashes; select group based upon C<group> key.

Create the iterator with

  sub ( $gathered, $state ) {

      # if nothing in the list, charge ahead
      return GATHER_ELEMENT_INCLUDE | GATHER_CYCLE_CONTINUE
        if ! $gathered->@*;

      # If the current element's key is the same as the last
      # gathered one, gather
      return GATHER_ELEMENT_INCLUDE | GATHER_CYCLE_CONTINUE
        if $gathered->[-1]{group} eq $_->{group};

      # have a different key, need to start a new group. cache
      # the current value to use in the next cycle
      return GATHER_ELEMENT_CACHE | GATHER_CYCLE_CONTINUE;
  }

=head2 Far too complex an example

Batch integer elements into groups of 10, only accept even numbers,
and drops the last batch if it has fewer than ten, but only if the
last element isn't 100.

  sub ( $gathered, $state ) {

      return $gathered->@* && $gathered->[-1] == 100 ? GATHER_CYCLE_STOP : GATHER_CYCLE_ABORT
        if $state == GATHER_SRC_EXHAUSTED;

      return GATHER_ELEMENT_EXCLUDE | GATHER_CYCLE_CONTINUE
        if $_ % 2;

      return GATHER_ELEMENT_INCLUDE
        | ( $gathered->@* == 9 ? GATHER_CYCLE_RESTART : GATHER_CYCLE_CONTINUE );
  }

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-iterator-flex@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Iterator-Flex>

=head2 Source

Source is available at

  https://gitlab.com/djerius/iterator-flex

and may be cloned from

  https://gitlab.com/djerius/iterator-flex.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Iterator::Flex|Iterator::Flex>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
