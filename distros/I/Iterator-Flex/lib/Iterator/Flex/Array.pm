package Iterator::Flex::Array;

# ABSTRACT: Array Iterator Class

use strict;
use warnings;

our $VERSION = '0.19';

use Iterator::Flex::Utils ':IterAttrs';
use Ref::Util;
use namespace::clean;
use experimental 'signatures';

use parent 'Iterator::Flex::Base';






























sub new ( $class, $array, $pars = {} ) {
    $class->_throw( parameter => "argument must be an ARRAY reference" )
      unless Ref::Util::is_arrayref( $array );

    $class->SUPER::new( { array => $array }, $pars );
}


sub construct ( $class, $state ) {

    $class->_throw( parameter => "'state' parameter must be a HASH reference" )
      unless Ref::Util::is_hashref( $state );

    my ( $arr, $prev, $current, $next )
      = @{$state}{qw[ array prev current next ]};

    $class->_throw( parameter => "state 'array' parameter must be a HASH reference" )
      unless Ref::Util::is_arrayref( $arr );

    my $len = @$arr;

    $next = 0 unless defined $next;

    $class->_throw( parameter => "illegal value for state 'prev' argument" )
      if defined $prev && ( $prev < 0 || $prev >= $len );

    $class->_throw( parameter => "illegal value for state 'current' argument" )
      if defined $current && ( $current < 0 || $current >= $len );

    $class->_throw( parameter => "illegal value for state 'next' argument" )
      if $next < 0 || $next > $len;

    my $self;

    return {

        ( +_SELF ) => \$self,

        ( +RESET ) => sub {
            $prev = $current = undef;
            $next = 0;
        },

        ( +REWIND ) => sub {
            $next = 0;
        },

        ( +PREV ) => sub {
            return defined $prev ? $arr->[$prev] : undef;
        },

        ( +CURRENT ) => sub {
            return defined $current ? $arr->[$current] : undef;
        },

        ( +NEXT ) => sub {
            if ( $next == $len ) {
                # if first time through, set prev
                $prev = $current
                  if !$self->is_exhausted;
                return $current = $self->signal_exhaustion;
            }
            $prev    = $current;
            $current = $next++;

            return $arr->[$current];
        },

        ( +FREEZE ) => sub {
            return [
                $class,
                {
                    array   => $arr,
                    prev    => $prev,
                    current => $current,
                    next    => $next,
                },
            ];
        },
    };
}


__PACKAGE__->_add_roles( qw[
      State::Registry
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

Iterator::Flex::Array - Array Iterator Class

=head1 VERSION

version 0.19

=head1 METHODS

=head2 new

  $iterator = Iterator::Flex::Array->new( $array_ref, ?\%pars );

Wrap an array in an iterator.

The optional C<%pars> hash may contain standard L<signal
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
