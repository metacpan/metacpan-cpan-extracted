package Iterator::Flex::Cat;

# ABSTRACT: An iterator which concatenates a set of iterators

use v5.28;
use strict;
use warnings;
use experimental qw( signatures declared_refs refaliasing );

our $VERSION = '0.32';

use Iterator::Flex::Utils qw( RETURN STATE EXHAUSTION :IterAttrs :IterStates can_meth );
use Iterator::Flex::Factory 'to_iterator';
use parent 'Iterator::Flex::Base';
use List::Util 'all';

use namespace::clean;





































sub new ( $class, @args ) {
    my $pars = Ref::Util::is_hashref( $args[-1] ) ? pop @args : {};

    @args
      or throw_failure( parameter => 'not enough parameters' );

    $class->SUPER::new( {
            depends                => \@args,
            current_iterator_index => undef,
        },
        $pars,
    );
}

sub construct ( $class, $state ) {
    throw_failure( parameter => q{state must be a HASH reference} )
      unless Ref::Util::is_hashref( $state );

    $state->{value} //= [];

    my ( \@depends, $current_iterator, $prev, $current, $next, undef )
      = @{$state}{ 'depends', 'current_iterator', 'prev', 'current', 'next', 'thaw' };

    # transform into iterators if required.
    my @iterators
      = map { to_iterator( $_, { ( +EXHAUSTION ) => RETURN } ) } @depends;

    # -- not sure if this is just cargo-culted
    # my $value;
    # $value = $current
    #   if $thaw;

    my $self;
    my $iterator_state;
    my $iter;
    my $is_exhausted;

    my sub init {
        $current_iterator //= 0;
        if ( $current_iterator >= @iterators ) {
            $iterator_state = IterState_EXHAUSTED;
        }
        else {
            $iter         = $iterators[$current_iterator];
            $is_exhausted = $iter->can( 'is_exhausted' );
        }
    }

    init();

    my %params = (

        ( +_SELF ) => \$self,

        ( +STATE ) => \$iterator_state,

        ( +NEXT ) => sub {
            return $self->signal_exhaustion if $iterator_state == IterState_EXHAUSTED;

            while ( 1 ) {
                my $value = $iter->();
                if ( defined $value || !$iter->$is_exhausted ) {
                    $prev    = $current;
                    $current = $value;
                    return $current;
                }

                last if ++$current_iterator >= @iterators;
                $iter         = $iterators[$current_iterator];
                $is_exhausted = $iter->can( 'is_exhausted' );
            }

            # if we haven't returned, we've exhausted things
            $current_iterator = undef;
            $prev             = $current;
            return $current = $self->signal_exhaustion;
        },

        ( +PREV ) => sub {
            return $prev;
        },

        ( +CURRENT ) => sub {
            return $self->signal_exhaustion if $iterator_state eq IterState_EXHAUSTED;
            return $current;
        },

        ( +_ROLES ) => [],

        ( +_DEPENDS ) => \@iterators,
    );

    # can only freeze if the iterators support a current method
    if ( all { defined can_meth( $_, 'current' ) } @iterators ) {
        $params{ +FREEZE } = sub {
            return [
                $class,
                {
                    current_iterator => $current_iterator,
                    prev             => $prev,
                    current          => $current,
                    next             => $next,
                } ];
        };
        push $params{ +_ROLES }->@*, 'Freeze';
    }

    if ( all { defined can_meth( $_, 'reset' ) } @iterators ) {
        $params{ +RESET } = sub {
            $prev = $current = $current_iterator = undef;
            init();
        };
        push $params{ +_ROLES }->@*, 'Reset::Closure';
    }

    if ( all { defined can_meth( $_, 'rewind' ) } @iterators ) {
        $params{ +REWIND } = sub {
            $current_iterator = undef;
            init();
        };
        push $params{ +_ROLES }->@*, 'Rewind::Closure';
    }

    $params{ +_NAME } = 'icat';
    return \%params;
}


__PACKAGE__->_add_roles( qw[
      State::Closure
      Next::ClosedSelf
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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Iterator::Flex::Cat - An iterator which concatenates a set of iterators

=head1 VERSION

version 0.32

=head1 METHODS

=head2 new

  $iterator = Iterator::Flex::Cat->new( $iterable1, $iterable2, ..., ?\%pars );

Returns an iterator which produces a concatenation of the input iterables.

The iterables are converted into iterators via L<Iterator::Flex::Factory/to_iterator> if required.

The optional C<%pars> hash may contain standard L<signal
parameters|Iterator::Flex::Manual::Overview/Signal Parameters>.

The iterator supports the following capabilities:

=over

=item current

=item next

=item reset

If supported by all of the iterables

=item rewind

If supported by all of the iterables

=item freeze

This iterator may be frozen only if all of the iterables support the
C<prev> or C<__prev__> method.

=back

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
