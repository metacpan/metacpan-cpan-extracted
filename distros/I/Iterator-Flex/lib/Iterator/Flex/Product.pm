package Iterator::Flex::Product;

# ABSTRACT: An iterator which produces a Cartesian product of iterators

use strict;
use warnings;
use experimental qw( signatures declared_refs refaliasing );

our $VERSION = '0.19';

use Iterator::Flex::Utils qw( RETURN STATE EXHAUSTION :IterAttrs :IterStates );
use Iterator::Flex::Factory;
use parent 'Iterator::Flex::Base';
use Ref::Util;
use List::Util;


use namespace::clean;











































sub new ( $class, @args ) {
    my $pars = Ref::Util::is_hashref( $args[-1] ) ? pop @args : {};

    $class->_throw( parameter => 'not enough parameters' )
      unless @args;

    my @iterators;
    my @keys;

    # distinguish between ( key => iterator, key =>iterator ) and ( iterator, iterator );
    if ( Ref::Util::is_ref( $args[0] ) ) {
        @iterators = @args;
    }
    else {
        $class->_throw( parameter => 'expected an even number of arguments' )
          if @args % 2;

        while ( @args ) {
            push @keys,      shift @args;
            push @iterators, shift @args;
        }
    }

    $class->SUPER::new( { keys => \@keys, depends => \@iterators, value => [] }, $pars );
}

sub construct ( $class, $state ) {
    $class->_throw( parameter => "state must be a HASH reference" )
      unless Ref::Util::is_hashref( $state );

    $state->{value} //= [];

    my ( \@depends, \@keys, \@value, $thaw )
      = @{$state}{qw[ depends keys value thaw ]};

    # transform into iterators if required.
    my @iterators
      = map { Iterator::Flex::Factory->to_iterator( $_, { ( +EXHAUSTION ) => +RETURN } ) } @depends;

    # can only work if the iterators support a rewind method
    $class->_throw( parameter => "all iterables must provide a rewind method" )
      unless List::Util::all { defined $class->_can_meth( $_, 'rewind' ) } @iterators;

    $class->_throw( parameter => "number of keys not equal to number of iterators" )
      if @keys && @keys != @iterators;

    @value = map { $_->current } @iterators
      if $thaw;

    my @set = ( 1 ) x @value;

    my $self;
    my $iterator_state;
    my %params = (

        ( +_SELF ) => \$self,

        ( +STATE ) => \$iterator_state,

        ( +NEXT ) => sub {
            return $self->signal_exhaustion if $iterator_state == +IterState_EXHAUSTED;

            # first time through
            if ( !@value ) {

                for my $iter ( @iterators ) {
                    push @value, $iter->();

                    if ( $iter->is_exhausted ) {
                        return $self->signal_exhaustion;
                    }
                }

                @set = ( 1 ) x @value;
            }

            else {

                $value[-1] = $iterators[-1]->();
                if ( $iterators[-1]->is_exhausted ) {
                    $set[-1] = 0;
                    my $idx = @iterators - 1;
                    while ( --$idx >= 0 ) {
                        $value[$idx] = $iterators[$idx]->();
                        last unless $iterators[$idx]->is_exhausted;
                        $set[$idx] = 0;
                    }

                    if ( !$set[0] ) {
                        return $self->signal_exhaustion;
                    }

                    while ( ++$idx < @iterators ) {
                        $iterators[$idx]->rewind;
                        $value[$idx] = $iterators[$idx]->();
                        $set[$idx]   = 1;
                    }
                }

            }
            if ( @keys ) {
                my %value;
                @value{@keys} = @value;
                return \%value;
            }
            else {
                return [@value];
            }
        },

        ( +CURRENT ) => sub {
            return undef                    if !@value;
            return $self->signal_exhaustion if $iterator_state eq +IterState_EXHAUSTED;
            if ( @keys ) {
                my %value;
                @value{@keys} = @value;
                return \%value;
            }
            else {
                return [@value];
            }
        },

        ( +RESET )    => sub { @value = () },
        ( +REWIND )   => sub { @value = () },
        ( +_DEPENDS ) => \@iterators,
    );

    # can only freeze if the iterators support a current method
    if (
        List::Util::all { defined $class->_can_meth( $_, 'current' ) }
        @iterators
      )
    {

        $params{ +FREEZE } = sub {
            return [ $class, { keys => \@keys } ];
        };
        $params{ +_ROLES } = ['Freeze'];
    }

    $params{ +_NAME } = 'iproduct';
    return \%params;
}


__PACKAGE__->_add_roles( qw[
      State::Closure
      Next::ClosedSelf
      Current::Closure
      Reset::Closure
      Rewind::Closure
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

Iterator::Flex::Product - An iterator which produces a Cartesian product of iterators

=head1 VERSION

version 0.19

=head1 METHODS

=head2 new

  $iterator = Iterator::Flex::Product->new( $iterable1, $iterable2, ..., ?\%pars );
  $iterator = Iterator::Flex::Product->new( key1 => $iterable1,
                              key2 => iterable2, ..., ?\%pars );

Returns an iterator which produces a Cartesian product of the input iterables.
If the input to B<iproduct> is a list of iterables, C<$iterator> will return an
array reference containing an element from each iterable.

If the input is a list of key, iterable pairs, C<$iterator> will return a
hash reference.

The iterables are converted into iterators via L<Iterator::Flex::Factory/to_iterator> if required.

All of the iterables must support the C<rewind> method.

The optional C<%pars> hash may contain standard L<signal
parameters|Iterator::Flex::Manual::Overview/Signal Parameters>.

The iterator supports the following capabilities:

=over

=item current

=item next

=item reset

=item rewind

=item freeze

This iterator may be frozen only if all of the iterables support the
C<prev> or C<__prev__> method.

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
