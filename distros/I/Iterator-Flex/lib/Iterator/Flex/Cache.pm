package Iterator::Flex::Cache;

# ABSTRACT: Cache Iterator Class

use strict;
use warnings;
use experimental qw( signatures postderef );

our $VERSION = '0.19';

use parent 'Iterator::Flex::Base';
use Iterator::Flex::Utils qw( STATE :IterAttrs :IterStates throw_failure );
use Iterator::Flex::Factory;
use Scalar::Util;
use Ref::Util;

use namespace::clean;










































sub new ( $class, $iterable, $pars = {} ) {

    throw_failure( parameter => '"pars" argument must be a hash' )
      unless Ref::Util::is_hashref( $pars );

    my %pars = $pars->%*;

    my $capacity = delete $pars{capacity} // 2;

    $class->SUPER::new( {
            capacity => $capacity,
            depends  => [ Iterator::Flex::Factory->to_iterator( $iterable ) ],
        },
        \%pars
    );
}










sub construct ( $class, $state ) {

    $class->_throw( parameter => "state must be a HASH reference" )
      unless Ref::Util::is_hashref( $state );

    my ( $src, $capacity, $idx, $cache ) = @{$state}{qw[ depends capacity idx cache ]};
    $src = $src->[0];
    $idx   //= -1;
    $cache //= [];

    my $self;
    my $iterator_state;

    return {

        ( +_SELF ) => \$self,

        ( +STATE ) => \$iterator_state,

        ( +RESET ) => sub {
            $idx = -1;
            @{$cache} = ();
        },

        ( +REWIND ) => sub {
        },

        ( +PREV ) => sub {
            return defined $idx ? $cache->[ ( $idx - 1 ) % $capacity ] : undef;
        },

        ( +CURRENT ) => sub {
            return defined $idx ? $cache->[ $idx % $capacity ] : undef;
        },

        ( +NEXT ) => sub {

            return $self->signal_exhaustion
              if $iterator_state == +IterState_EXHAUSTED;

            $idx = ++$idx % $capacity;
            my $current = $cache->[$idx] = $src->();

            return $self->signal_exhaustion
              if $src->is_exhausted;

            return $current;
        },

        ( +METHODS ) => {
            at => sub ( $, $at ) {
                $cache->[ ( $idx - $at ) % $capacity ];
            },
        },

        ( +FREEZE ) => sub {
            return [ $class, { idx => $idx, capacity => $capacity, cache => $cache } ];
        },

        ( +_DEPENDS ) => $src,
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

Iterator::Flex::Cache - Cache Iterator Class

=head1 VERSION

version 0.19

=head1 METHODS

=head2 new

  $iterator = Iterator::Flex::Cache->new( $iterable, ?\%pars );

The iterator caches values of C<$iterable> (by default, the previous and current values),

C<$iterable> is converted into an iterator via L<Iterator::Flex::Factory/to_iterator> if required.

The optional C<%pars> hash may contain standard L<signal
parameters|Iterator::Flex::Manual::Overview/Signal Parameters> as well
as the following model parameters:

=over

=item capacity => I<integer>

The size of the cache.  It defaults to C<2>.

=back

The returned iterator supports the following capabilities:

=over

=item current

=item next

=item prev

=item rewind

=item reset

=item freeze

=back

=head2 at

   $value = $iter->at( $idx );

Returns the cache value at $idx.  The most recent value is at C<$idx = 0>,
and the last value is at C<$idx = $capacity - 1>.

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
