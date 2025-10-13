package Iterator::Flex::Flatten;

# ABSTRACT: Flatten Iterator Class

use v5.28;
use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.32';

use Iterator::Flex::Utils qw( STATE RETURN EXHAUSTION :IterAttrs :IterStates throw_failure);
use Iterator::Flex::Factory 'construct_from_iterable', 'to_iterator';
use Ref::Util 'is_plain_arrayref', 'is_plain_hashref', 'is_blessed_ref';
use parent 'Iterator::Flex::Base';

use namespace::clean;

















































sub new ( $class, $iterable, $pars = {} ) {
    $class->SUPER::new( { src => $iterable }, $pars );
}

## no critic( ExcessComplexity )
sub construct ( $class, $state ) {

    throw_failure( parameter => q{'state' parameter must be a HASH reference} )
      unless Ref::Util::is_hashref( $state );

    my ( $prev, $current, $idx, $iter )
      = @{$state}{qw[ prev current idx iter src ]};

    my $src = @{$state}{qw[ code src ]};

    $src = to_iterator( $src );

    my $self;
    my $iterator_state;

    my $is_exhausted      = $src->can( 'is_exhausted' );
    my $iter_is_exhausted = is_blessed_ref( $iter )
      && $iter->can( 'is_exhausted' );

    my $rewind = !!0;
    my $reset  = !!0;

    return {
        ( +_NAME ) => 'iflatten',

        ( +_SELF ) => \$self,

        ( +STATE ) => \$iterator_state,

        ( +PREV ) => sub {
            return $prev;
        },

        ( +CURRENT ) => sub {
            return $current;
        },

        ( +NEXT ) => sub {
            return $self->signal_exhaustion if $iterator_state == IterState_EXHAUSTED;

            my $value;

          LOOP:
            while ( 1 ) {

                if ( !defined $iter ) {

                    $value = $src->();
                    if ( !defined $value && $src->$is_exhausted ) {
                        $prev    = $current;
                        $current = undef;
                        return $self->signal_exhaustion;
                    }

                    # most likely
                    last LOOP
                      if !ref $value || is_plain_hashref( $value );

                    # handle arrays directly; could use an iterator, but this is
                    # faster
                    if ( is_plain_arrayref( $value ) ) {
                        $iter = $value;
                        $idx  = 0;
                    }
                    else {
                        $iter = construct_from_iterable(
                            $value,
                            {
                                +( EXHAUSTION )   => RETURN,
                                action_on_failure => RETURN,
                            } );
                        last LOOP if !defined $iter;

                        $iter_is_exhausted = $iter->can( 'is_exhausted' );

                        if ( $rewind ) {
                            throw_failure( Unsupported => 'unable to rewind element' )
                              unless $iter->can( 'rewind' );
                            $iter->rewind;
                        }
                        elsif ( $reset ) {
                            throw_failure( Unsupported => 'unable to reset element' )
                              unless $iter->can( 'reset' );
                            $iter->reset;
                        }
                    }
                }

                if ( defined $idx ) {
                    if ( $idx < $iter->@* ) {
                        $value = $iter->[ $idx++ ];
                        last LOOP;
                    }
                    $iter = $idx = undef;
                    next;
                }

                $value = $iter->();
                last LOOP
                  if defined $value || !$iter->$iter_is_exhausted;

                $iter = undef;
            }

            $prev = $current;
            return $current = $value;
        },

        ( +RESET ) => sub {
            $iter   = $idx = $prev = $current = undef;
            $rewind = !!0;
            $reset  = !!1;
        },
        ( +REWIND ) => sub {
            $iter   = $idx = undef;
            $reset  = !!0;
            $rewind = !!1;
        },
        ( +_DEPENDS ) => $src,
    };
}


__PACKAGE__->_add_roles( qw[
      Current::Closure
      Next::ClosedSelf
      Prev::Closure
      Reset::Closure
      Rewind::Closure
      State::Closure
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

Iterator::Flex::Flatten - Flatten Iterator Class

=head1 VERSION

version 0.32

=head1 METHODS

=head2 new

  $iterator = Ierator::Flex::Flatten->new( $iterable, ?\%pars );

For each value that C<$iterable> yields, iterate over it if its an
iterable, otherwise return it.

For example, if

   $iterable = [ iseq(1,3), 4, [ 5,6,7 ], [ [8,9,10] ] ]

C<$iterator> yields

   1, 2, 3, 4, 5, 6, 7, [ 8, 9, 10 ]

C<$iterable> is converted into an iterator via
L<Iterator::Flex::Factory/to_iterator> if required.

The optional C<%pars> hash may contain standard L<signal
parameters|Iterator::Flex::Manual::Overview/Signal Parameters>.

The iterator supports the following capabilities:

=over

=item next

=item current

=item prev

Z<>

=item reset

=item rewind

B<reset> and B<rewind> are fully supported if all of the elements
generated by C<$iterable> support them (arrays do).  As it is not
known if an element supports these until it is retrieved from
C<$iterable>, a rewind or reset operation will not immediately throw
an exception. Instead, it will be thrown when C<$iteratable> is
advanced to an element which does not support them.

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
