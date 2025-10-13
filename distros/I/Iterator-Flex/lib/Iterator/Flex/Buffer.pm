package Iterator::Flex::Buffer;

# ABSTRACT: Buffer Iterator Class

use v5.28;
use strict;
use warnings;

our $VERSION = '0.32';

use Iterator::Flex::Utils ':IterAttrs', ':IterStates', ':SignalParameters', ':ExhaustionActions';
use Iterator::Flex::Factory 'to_iterator';
use Ref::Util;
use namespace::clean;
use experimental 'signatures';

use parent 'Iterator::Flex::Base';






































sub new ( $class, $iterable, $capacity = 0, $pars = {} ) {

    my %pars = $pars->%*;
    $capacity //= 0;

    Scalar::Util::looks_like_number( $capacity ) && int( $capacity ) == $capacity && $capacity >= 0
      or throw_failure(
        parameter => "parameter 'capacity' ($capacity) is not a positive or zero integer" );

    $class->SUPER::new( {
            capacity => $capacity,
            src      => $iterable,
        },
        \%pars,
    );
}

sub construct ( $class, $state ) {

    throw_failure( parameter => q{'state' parameter must be a HASH reference} )
      unless Ref::Util::is_hashref( $state );

    my ( $src, $prev, $current, $next, $array, $capacity )
      = @{$state}{qw[ src prev current next array capacity ]};

    $src
      = to_iterator( $src, { ( +EXHAUSTION ) => THROW } );

    my $nread = defined $array ? $array->@* - 1 : 0;
    $next //= 1;
    my $self;

    my $iterator_state;
    my $src_is_exhausted = !!0;

    return {

        ( +_NAME ) => 'ibuffer',

        ( +_SELF ) => \$self,

        ( +STATE ) => \$iterator_state,

        ( +RESET ) => sub {
            $src_is_exhausted = !!0;
            $prev             = $current = undef;
            $next             = 1;
            $nread            = 0;
        },

        ( +REWIND ) => sub {
            $src_is_exhausted = !!0;
            $next             = 1;
            $nread            = 0;
        },

        ( +PREV ) => sub {
            return defined $prev ? $array->[$prev] : undef;
        },

        ( +CURRENT ) => sub {
            return defined $current ? $array->[$current] : undef;
        },

        ( +NEXT ) => sub {

            return $self->signal_exhaustion
              if $iterator_state == IterState_EXHAUSTED;

            # load buffer; need to handle both initial and recurrent loads,
            # keeping track of the previous value.
            if ( $next > $nread ) {

                if ( $src_is_exhausted ) {
                    $prev = $current;
                    return $self->signal_exhaustion;
                }

                $array //= [];
                my $prev_value = defined $current ? $array->[$current] : undef;

                # $array has one more element than $capacity to
                # ensure there's room for the previous value when
                # we load the next buffer.
                $array->@* = ( $prev_value );

                eval {
                    # preload $array
                    push $array->@*, $src->next;

                    # postfix until/while check conditional first,
                    # which would be a problem if $array->@* and
                    # capacity == 0, in which case it would never
                    # call $src->next
                    push( $array->@*, $src->next ) until $array->@* == $capacity + 1;
                    1;
                } or do {
                    die $@
                      unless Ref::Util::is_blessed_ref( $@ )
                      && $@->isa( 'Iterator::Flex::Failure::Exhausted' );
                    $src_is_exhausted = !!1;
                    if ( $array->@* == 1 ) {
                        $current = $prev = 0;    # setup for rewind
                        return $self->signal_exhaustion;
                    }
                };

                $nread   = $array->@* - 1;
                $current = 0;
                $next    = 1;
            }

            $prev    = $current;
            $current = $next;
            $next++;
            return $array->[$current];
        },

        # this iterator only depends on $src if it hasn't drained it.
        # currently _DEPENDS must be a list of iterators, not a
        # coderef, so a dynamic dependency is no tpossible
        ( +_DEPENDS ) => $src,
        ( +FREEZE )   => sub {
            return [
                $class,
                {
                    src      => $src,
                    prev     => $prev,
                    current  => $current,
                    next     => $next,
                    array    => $array,
                    capacity => $capacity,
                },
            ];
        },
    };
}


__PACKAGE__->_add_roles( qw[
      State::Closure
      Next::ClosedSelf
      Rewind::Closure
      Reset::Closure
      Prev::Closure
      Current::Closure
      Freeze
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

Iterator::Flex::Buffer - Buffer Iterator Class

=head1 VERSION

version 0.32

=head1 METHODS

=head2 new

  $iterator = Ierator::Flex::Buffer->new( $iterable, $capacity, ?\%pars );

Returns an iterator which on the first call to C<next> extracts
C<$capacity> elements from C<$iterable>, stores them in a buffer,
and then returns them one by one.  When the buffer is exhausted, it
repeats the process.

If C<$capacity> is zero, the C<$iterator> is drained into a buffer.

C<$iterable> is converted into an iterator via
L<Iterator::Flex::Factory/to_iterator> if required.

The C<%pars> hash may contain standard L<signal
parameters|Iterator::Flex::Manual::Overview/Signal Parameters>.

The returned iterator supports the following capabilities:

=over

=item current

=item next

=item prev

=item rewind

=item reset

=item freeze

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
