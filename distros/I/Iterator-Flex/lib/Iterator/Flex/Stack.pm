package Iterator::Flex::Stack;

# ABSTRACT: An iterator which concatenates a set of iterators

use strict;
use warnings;
use experimental qw( signatures declared_refs refaliasing );

our $VERSION = '0.31';

use Iterator::Flex::Utils qw( RETURN STATE EXHAUSTION :IterAttrs :IterStates );
use Iterator::Flex::Factory 'to_iterator';
use parent 'Iterator::Flex::Base';
use List::Util 'all';

use namespace::clean;

















































sub new ( $class, @args ) {
    my $pars = Ref::Util::is_hashref( $args[-1] ) ? pop @args : {};

    $class->SUPER::new( {
            depends                => \@args,
            current_iterator_index => undef,
        },
        $pars
    );
}

sub construct ( $class, $state ) {
    throw_failure( parameter => q{state must be a HASH reference} )
      unless Ref::Util::is_hashref( $state );

    $state->{value} //= [];

    my ( \@depends, $prev, $current, undef, undef )
      = @{$state}{ 'depends', 'prev', 'current', 'next', 'thaw' };

    # transform into iterators if required.
    my @stack
      = map { to_iterator( $_, { ( +EXHAUSTION ) => RETURN } ) } @depends;
    my @snapshot = @stack;

    # --- cargo cult??
    # my $value;
    # $value = $current
    #   if $thaw;

    my $self;

    my $iter;
    my $is_exhausted;
    my $iterator_state;

    my sub init {
        $iterator_state = IterState_EXHAUSTED;
        if ( @stack ) {
            $iter           = $stack[0];
            $is_exhausted   = $iter->can( 'is_exhausted' );
            $iterator_state = IterState_CLEAR;
        }
    }
    init();

    my %params = (

        ( +_NAME ) => 'istack',

        ( +_SELF ) => \$self,

        ( +RESET ) => sub {
            $prev  = $current = undef;
            @stack = @snapshot;
            init();
        },

        ( +REWIND ) => sub {
            @stack = @snapshot;
            init();
        },

        ( +STATE ) => \$iterator_state,

        ( +NEXT ) => sub {
            return $self->signal_exhaustion if $iterator_state == IterState_EXHAUSTED;

            while ( 1 ) {
                my $value = $iter->();

                if ( defined( $value ) || !$iter->$is_exhausted ) {
                    $prev = $current;
                    return $current = $value;
                }

                last unless defined( $iter = shift @stack );
                $is_exhausted = $iter->can( 'is_exhausted' );
            }

            $prev = $current;
            return $current = $self->signal_exhaustion;
        },

        ( +PREV ) => sub {
            return $prev;
        },

        ( +CURRENT ) => sub {
            return $self->signal_exhaustion if !@stack;
            return $current;
        },

        ( +_ROLES ) => [],

        ( +_DEPENDS ) => \@snapshot,

        ( +METHODS ) => {
            push => sub ( $, @iters ) {
                push @stack, map { to_iterator( $_, { ( +EXHAUSTION ) => RETURN } ) } @iters;
                $self->_clear_state;
                init() if @stack == 1;
            },

            pop => sub ($) {
                if ( @stack == 1 ) {
                    $iterator_state = IterState_EXHAUSTED;
                    $iter           = $is_exhausted = undef;
                }
                return CORE::pop( @stack );
            },

            unshift => sub ( $, @iters ) {
                unshift @stack, map { to_iterator( $_, { ( +EXHAUSTION ) => RETURN } ) } @iters;
                init();
            },

            shift => sub ($) {
                if ( @stack == 1 ) {
                    $iterator_state = IterState_EXHAUSTED;
                    $iter           = $is_exhausted = undef;
                }
                my $ret = CORE::shift( @stack );
                init();
                return $ret;
            },

            snapshot => sub ($) {
                @snapshot = @stack;
            },
        },

    );

    return \%params;
}


__PACKAGE__->_add_roles( qw[
      State::Closure
      Next::ClosedSelf
      Rewind::Closure
      Reset::Closure
      Current::Closure
      Prev::Closure
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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory unshifting

=head1 NAME

Iterator::Flex::Stack - An iterator which concatenates a set of iterators

=head1 VERSION

version 0.31

=head1 METHODS

=head2 new

  $iterator = Iterator::Flex::Stack->new( @iterables, ..., ?\%pars );

Returns an iterator which manages a stack of iterators.  The iterator
supports the L<pop>, L<push>, L<shift>, L<unshift> methods, which have
the same API as the Perl builtin subroutines.

If the stack iterator is exhausted, pushing (or unshifting) a new
iterator onto it will reset the state to the
L<Iteration|/Iterator::Flex::Manual::Overview/Iteration State>
state. The C<current> and C<prev> methods will return The next
L</next> operation will retrieve the first element from the data
stream,

It also provides a L<snapshot> method, which records the iterators 
in the stack.  This snapshot is used when the C<rewind> or C<reset>
methods are called.  An initial snapshot is taken when the iterator
is first constructed.

The iterator returns the next value from the iterator at the top of
the stack.  Iterators are popped when they are exhausted.

The iterables are converted into iterators via
L<Iterator::Flex::Factory/to_iterator> if required.

The optional C<%pars> hash may contain standard L<signal
parameters|Iterator::Flex::Manual::Overview/Signal Parameters>.

The iterator supports the following capabilities:

=over

=item current

=item next

=back

Because the nature of the iterators on the stack may vary, the
C<reset> and C<rewind> methods may throw at runtime if an iterator on
the stack does not support the required facilities.

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
