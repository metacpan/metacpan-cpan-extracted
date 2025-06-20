package Iterator::Flex::Role::Reset::Closure;

# ABSTRACT: Implement C<reset> as a closure stored in the registry

use strict;
use warnings;

our $VERSION = '0.19';

use Scalar::Util;
use List::Util;

use Iterator::Flex::Base  ();
use Iterator::Flex::Utils qw( :default ITERATOR RESET );
use Role::Tiny;
use experimental 'signatures';

use namespace::clean;











sub reset ( $self ) {
    $self->_apply_method_to_depends( 'reset' );

    $REGISTRY{ refaddr $self }{ +ITERATOR }{ +RESET }->( $self );
    $self->_clear_state;

    return;
}
*__reset__ = \&reset;


requires '_clear_state';
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

Iterator::Flex::Role::Reset::Closure - Implement C<reset> as a closure stored in the registry

=head1 VERSION

version 0.19

=head1 METHODS

=head2 reset

=head2 __reset__

   $iterator->reset;

Resets the iterator to its initial value.

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
