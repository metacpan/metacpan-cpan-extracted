package Iterator::Flex::Permute;

# ABSTRACT: Permute Iterator Class

use strict;
use warnings;
use experimental qw( signatures postderef declared_refs );

our $VERSION = '0.30';

use parent 'Iterator::Flex::Base';
use Iterator::Flex::Utils qw( :IterAttrs :IterStates throw_failure );
use Iterator::Flex::Factory;
use Scalar::Util;
use Ref::Util 'is_hashref', 'is_arrayref';

use namespace::clean;




































sub new ( $class, $array, $pars = {} ) {

    throw_failure( parameter => q{'array' argument must be an array} )
      unless is_arrayref( $array );

    throw_failure( parameter => q{'pars' argument must be a hash} )
      unless is_hashref( $pars );

    my %pars = $pars->%*;
    my $k    = delete $pars{k} // $array->@*;
    my $n    = $array->@*;

    defined $k && Scalar::Util::looks_like_number( $k ) && int( $k ) == $k && $k > 0
      || throw_failure( parameter => 'k parameter is not a positive integer' );

    throw_failure( parameter => "size of subset (k = $k) > size of set ( $n )" )
      if $k > $n;

    $class->SUPER::new( { k => $k, array => $array, }, \%pars );
}


my sub permutations;

sub construct ( $class, $state ) {

    $class->_throw( parameter => q{state must be a HASH reference} )
      unless Ref::Util::is_hashref( $state );

    my ( $array, $k, $idx, $value, $c, $i, $restart ) = @{$state}{
        qw[ array k idx value
          c i restart
        ] };

    $value //= [];

    $c       //= [ ( 0 ) x $k ];
    $i       //= 1;
    $restart //= !!0;

    my $self;
    my $iterator_state;
    my $n = $array->@*;

    my %params = (

        ( +_SELF ) => \$self,

        ( +STATE ) => \$iterator_state,


        ( +CURRENT ) => sub {
            return $idx ? [ $value->@* ] : undef;
        },

        ( +RESET ) => sub {
            $i       = 1;
            $c       = [ ( 0 ) x $k ];
            $restart = !!0;

            $idx = undef;
            $value->@* = ();
        },

        +( REWIND ) => sub {
            $i       = 1;
            $c       = [ ( 0 ) x $k ];
            $restart = !!0;
            $idx     = undef;
        },

    );

    if ( $n == $k ) {

        $params{ +NEXT } = sub {
            return $self->signal_exhaustion
              if $iterator_state == IterState_EXHAUSTED;

            my \@value = $value;
            my \@array = $array;

            if ( !defined $idx ) {
                $idx = [ 0 .. $k - 1 ];
            }
            else {
                $i = permutations( $c, $i, $n, $idx, $restart );
                return $self->signal_exhaustion if !defined $i;
                $restart = !!1;
            }
            @value = @array[ $idx->@* ];
            return [@value];
        };

    }

    else {
        my $combination = @{$state}{'combination'};
        $combination //= [ 0 .. $k - 1 ];

        my \@combination = $combination;

        $params{ +NEXT } = sub {

            return $self->signal_exhaustion
              if $iterator_state == IterState_EXHAUSTED;

            my \@value = $value;
            my \@array = $array;

            if ( !defined $idx ) {
                $idx = [ 0 .. $k - 1 ];
            }
            else {
                $i = permutations( $c, $i, $k, $idx, $restart );
                if ( !defined $i ) {
                    next_combination( \@combination, $n )
                      or return $self->signal_exhaustion;
                    $i       = 1;
                    $c       = [ ( 0 ) x $k ];
                    $restart = !!0;
                    $idx     = [ 0 .. $k - 1 ];
                }
                else {
                    $restart = !!1;
                }
            }
            @value = @array[ @combination[ $idx->@* ] ];
            return [@value];
        };
    }

    return \%params;
}


# https://en.wikipedia.org/wiki/Heap%27s_algorithm

# procedure permutations(n : integer, A : array of any):
#     // c is an encoding of the stack state.
#     // c[k] encodes the for-loop counter for when permutations(k + 1, A) is called
#     c : array of int
#
#     for i := 0; i < n; i += 1 do
#         c[i] := 0
#     end for
#
#     output(A)
#
#     // i acts similarly to a stack pointer
#     i := 1;
#     while i < n do
#         if  c[i] < i then
#             if i is even then
#                 swap(A[0], A[i])
#             else
#                 swap(A[c[i]], A[i])
#             end if
#             output(A)
#             // Swap has occurred ending the while-loop. Simulate the
#             // increment of the while-loop counter
#             c[i] += 1
#             // Simulate recursive call reaching the base case by
#             // bringing the pointer to the base case analog in the
#             // array
#             i := 1
#         else
#             // Calling permutations(i+1, A) has ended as the
#             // while-loop terminated. Reset the state and simulate
#             // popping the stack by incrementing the pointer.
#             c[i] := 0
#             i += 1
#         end if
#     end while

#
sub permutations ( $c, $i, $n, $A, $restart ) {

    # these are initialized outside of here.
    my \@c = $c;
    my \@A = $A;

    while ( $i < $n ) {
        if ( $c[$i] < $i ) {

            if ( $restart ) {
                $restart = !!0;
                $c[$i] += 1;
                $i = 1;
                next;
            }

            if ( 0 == ( $i % 2 ) ) {
                my $t = $A[$i];
                $A[$i] = $A[0];
                $A[0] = $t;
            }
            else {
                my $t = $A[$i];
                $A[$i] = $A[ $c[$i] ];
                $A[ $c[$i] ] = $t;
            }
            return $i;

        }
        else {
            $c[$i] = 0;
            $i++;
        }
    }

    return undef;
}

# see https://cs.stackexchange.com/a/161542

sub next_combination ( $A, $n ) {

    my \@A = $A;
    my $k = @A;

    # for ( my $i = $k - 1 ; $i >= 0 ; $i-- ) {
    for my $i ( reverse 0 .. $k - 1 ) {
        if ( $A[$i] < $n - $k + $i ) {
            $A[$i]++;
            for my $j ( $i + 1 .. $k - 1 ) {
                $A[$j] = $A[ $j - 1 ] + 1;
            }
            return !!1;
        }
    }
    return !!0;
}


# Brute Force, slow

#   my \@idx = $idx;

#   my $last_slot;
#   my $overflow;
# BACKWARDS:
#   for my $slot ( reverse 0 .. $k - 1 ) {
#       $last_slot = $slot;
#       my $iarr = $idx[$slot];

#       $overflow = !!0;
#       while ( $iarr++ < $n - 1 ) {
#           next if elem_num( $iarr, @idx[ 0 .. $slot - 1 ] );
#           $idx[$slot] = $iarr;
#           last BACKWARDS;
#       }
#       $overflow = !!1;
#   }

#   return $self->signal_exhaustion if $last_slot == 0 && $overflow;

# FORWARDS:
#   for my $slot ( $last_slot + 1 .. $k - 1 ) {
#       for my $iarr ( 0 .. $n - 1 ) {
#           next if elem_num( $iarr, @idx[ 0 .. $slot - 1 ] );
#           $idx[$slot] = $iarr;
#           next FORWARDS;
#       }
#   }


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

Iterator::Flex::Permute - Permute Iterator Class

=head1 VERSION

version 0.30

=head1 METHODS

=head2 new

  $iterator = Iterator::Flex::Permute->new( $array, ?\%pars );

The iterator creates k-permutations of the input array.

The C<%pars> hash may contain standard L<signal
parameters|Iterator::Flex::Manual::Overview/Signal Parameters> as well
as the following model parameters:

=over

=item k => I<integer>

The number of elements in the subset. Defaults to the number in the full set if not specified.

=back

The returned iterator supports the following capabilities:

=over

=item current

=item next

=item rewind

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
