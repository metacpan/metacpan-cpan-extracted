package Iterator::Flex::Gather;

# ABSTRACT: Gather Iterator Class

use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.26';

use Iterator::Flex::Factory;
use Iterator::Flex::Utils qw[ THROW STATE EXHAUSTION :IterAttrs :IterStates ];
use Ref::Util;
use parent 'Iterator::Flex::Base';

use Iterator::Flex::Gather::Constants ':all';


use namespace::clean;






















































































sub new ( $class, $code, $iterable, $pars = {} ) {
    $class->_throw( parameter => q{'code' parameter is not a coderef} )
      unless Ref::Util::is_coderef( $code );

    $class->SUPER::new( { code => $code, src => $iterable }, $pars );
}


sub construct ( $class, $state ) {

    $class->_throw( parameter => q{'state' parameter must be a HASH reference} )
      unless Ref::Util::is_hashref( $state );

    my ( $code, $src ) = @{$state}{qw[ code src ]};

    $src
      = Iterator::Flex::Factory->to_iterator( $src, { ( +EXHAUSTION ) => THROW } );

    my $self;
    my $iterator_state;

    return {
        ( +_NAME ) => 'igather',

        ( +_SELF ) => \$self,

        ( +STATE ) => \$iterator_state,

        ( +NEXT ) => sub {
            return $self->signal_exhaustion
              if $iterator_state == IterState_EXHAUSTED;

            my $cycle;
            my @gathered;
            my $ret = eval {
                while ( 1 ) {
                    my $rv = $src->();
                    local $_ = $rv;
                    my $result = $code->( \@gathered, GATHER_GATHERING );

                    push @gathered, $rv
                      if ( $result & GATHER_ELEMENT_MASK ) == GATHER_ELEMENT_INCLUDE;

                    $cycle = $result & GATHER_CYCLE_MASK;
                    last if $cycle & ( GATHER_CYCLE_RESTART | GATHER_CYCLE_STOP | GATHER_CYCLE_ABORT );
                }
                1;
            };
            if ( !$ret && length $@ ) {
                die $@
                  unless Ref::Util::is_blessed_ref( $@ )
                  && $@->isa( 'Iterator::Flex::Failure::Exhausted' );

                local $_ = undef;
                return $self->signal_exhaustion
                  if $code->( \@gathered, GATHER_SRC_EXHAUSTED ) & GATHER_CYCLE_ABORT;
                $self->set_exhausted;
            }
            return \@gathered;
        },
        ( +RESET )    => sub { },
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

version 0.26

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
called while gathering items (B<GATHER_GATHERING>)or after the source
has been exhausted (B<GATHER_SRC_EXHAUSTED>).

It should return the binary AND of two result codes.

The first result code indicates whether the the element should be
gathered (B<GATHER_ELEMENT_INCLUDE>) or skipped (C<GATHER_ELEMENT_EXCLUDE>).

The second indicates whether the gathering cycle should stop and if
so, whether it should be restarted:

=over

=item GATHER_CYCLE_CONTINUE

Continue gathering.

=item GATHER_CYCLE_RESET

Stop gathering, and return the gathered items.  The next time the
iterator is invoked, it will begin a new cycle.

=item GATHER_CYCLE_STOP

Stop gathering, and return the gathered items.
The next time the iterator is invoked, it will signal exhaustion.

=item GATHER_CYCLE_ABORT

Stop gathering, and signal exhaustion.  Any gathered items are discarded.

=back

When the C<$iterable> signals exhaustion, C<$coderef> is called one
last time.  It should return either B<GATHER_CYCLE_STOP> or C<GATHER_CYCLE_ABORT>.

Here's an example for a gathering operation which batches integer
elements into groups of 10, only accepts even numbers, and drops the
last batch if it has fewer than ten, but only if the last element
isn't C<100>

  sub ( $gathered, $state ) {

      return $gathered->@* && $gathered->[-1] == 100 ? GATHER_CYCLE_STOP : GATHER_CYCLE_ABORT
        if $state == GATHER_SRC_EXHAUSTED;

      return GATHER_ELEMENT_EXCLUDE | GATHER_CYCLE_CONTINUE
        if $_ % 2;

      return GATHER_ELEMENT_INCLUDE
        | ( $gathered->@* == 9 ? GATHER_CYCLE_RESTART : GATHER_CYCLE_CONTINUE );

  }

The optional C<%pars> hash may contain standard L<signal
parameters|Iterator::Flex::Manual::Overview/Signal Parameters>.

The iterator supports the following capabilities:

=over

=item next

=item reset

=back

=head1 INTERNALS

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
