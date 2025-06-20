package Iterator::Flex::Role::Next::Closure;

# ABSTRACT: Construct a next() method for iterators without closed over $self

use strict;
use warnings;

our $VERSION = '0.19';

use Iterator::Flex::Utils 'NEXT';
use Scalar::Util;
use Role::Tiny;
use experimental 'signatures';

use namespace::clean;














sub _construct_next ( $class, $ipar, $ ) {

    # ensure we don't hold any strong references in the subroutine
    my $sub = $ipar->{ +NEXT } // $class->_throw( parameter => "Missing 'next' parameter" );
    Scalar::Util::weaken $ipar->{ +NEXT };
    return $sub;
}

sub next ( $self ) { &{$self}() }
*__next__ = \&next;

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

Iterator::Flex::Role::Next::Closure - Construct a next() method for iterators without closed over $self

=head1 VERSION

version 0.19

=head1 METHODS

=head2 next

=head2 __next__

   $iterator->next;

Wrapper for iterator next callback optimized for the case where
iterator exhaustion is handled by the iterator.  Typically this means
the iterator closure calls C<< $self->signal_exhaustion >>, which is added
by a specific C<Iterator::Flex::Role::Exhaustion> role.

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
