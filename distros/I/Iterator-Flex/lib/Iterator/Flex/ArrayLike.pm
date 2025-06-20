package Iterator::Flex::ArrayLike;

# ABSTRACT: ArrayLike Iterator Class

use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.19';

use Ref::Util;
use Iterator::Flex::Utils ':IterAttrs';
use namespace::clean;

use parent 'Iterator::Flex::Base';
use Role::Tiny::With ();
Role::Tiny::With::with 'Iterator::Flex::Role::Utils';




























































sub new ( $class, $obj, $pars = {} ) {

    $class->_croak( parameter => "argument must be a blessed reference" )
      unless Ref::Util::is_blessed_ref( $obj );

    $class->SUPER::new( { object => $obj }, $pars );
}

sub construct ( $class, $state ) {

    $class->_throw( parameter => "state must be a HASH reference" )
      unless Ref::Util::is_hashref( $state );

    my ( $obj, $prev, $current, $next, $length, $at )
      = @{$state}{qw[ object prev current next length at ]};

    $class->_throw( parameter => "state 'object' argument must be a blessed reference" )
      unless Ref::Util::is_blessed_ref( $obj );

    $length = $class->_resolve_meth( $obj, $length, 'length', 'len' );

    $at = $class->_resolve_meth( $obj, $at, 'at', 'getitem' );

    my $len = $obj->$length;

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
            return defined $prev ? $obj->$at( $prev ) : undef;
        },

        ( +CURRENT ) => sub {
            return defined $current ? $obj->$at( $current ) : undef;
        },

        ( +NEXT ) => sub {
            if ( $next == $len ) {
                # if first time through, set current
                $prev = $current
                  if !$self->is_exhausted;
                return $current = $self->signal_exhaustion;
            }
            $prev    = $current;
            $current = $next++;

            return $obj->$at( $current );
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

Iterator::Flex::ArrayLike - ArrayLike Iterator Class

=head1 VERSION

version 0.19

=head1 METHODS

=head2 new

  $iterator = Iterator::Flex::ArrayLike->new( $obj, ?\%pars );

Wrap an array-like object in an iterator.  An array like object must
provide two methods, one which returns the number of elements, and
another which returns the element at a given index.

The optional C<%pars> hash may contain standard L<signal
parameters|Iterator::Flex::Manual::Overview/Signal Parameters> as well
as the following model parameters:

=over

=item length => I<method name>

=item length => I<coderef>

The supplied argument will be used to determine the number of elements, via

   $nelem = $obj->$length;

If not specified, a method with name C<length> or C<__length__> or
C<len> or C<__len__> will be used if the object provides it.

=item at => I<method name>

=item at => I<coderef>

The supplied argument will be used to obtain the element at a specified index.

   $element = $obj->$at( $index );

If not specified, a method with name C<at> or C<__at__>, or C<getitem>
or C<__getitem__> will be used if the object provides it.

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
