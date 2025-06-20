package Iterator::Flex::Cycle;

# ABSTRACT: Array Cycle Iterator Class

use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.19';

use Iterator::Flex::Utils ':IterAttrs';
use Ref::Util;
use namespace::clean;

use parent 'Iterator::Flex::Base';




























sub new ( $class, $array, $ ) {

    $class->_throw( parameter => "argument must be an ARRAY reference" )
      unless Ref::Util::is_arrayref( $array );

    $class->SUPER::new( { array => $array }, {} );
}

sub construct ( $class, $state ) {

    $class->_throw( parameter => "state must be a HASH reference" )
      unless Ref::Util::is_hashref( $state );

    my ( $arr, $prev, $current, $next )
      = @{$state}{qw[ array prev current next ]};

    my $len = @$arr;

    $next = 0 unless defined $next;

    $class->_throw( parameter => "illegal value for 'prev'" )
      if defined $prev && ( $prev < 0 || $prev >= $len );

    $class->_throw( parameter => "illegal value for 'current'" )
      if defined $current && ( $current < 0 || $current >= $len );

    $class->_throw( parameter => "illegal value for 'next'" )
      if $next < 0 || $next > $len;


    return {

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
            $next    = 0 if $next == $len;
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
      Next::Closure
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

Iterator::Flex::Cycle - Array Cycle Iterator Class

=head1 VERSION

version 0.19

=head1 METHODS

=head2 new

  $iterator = Iterator::Flex::Cycle->new( $array_ref );

Wrap an array in an iterator which will cycle continuously through it.
The iterator is never exhausted.

The returned iterator supports the following methods:

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
