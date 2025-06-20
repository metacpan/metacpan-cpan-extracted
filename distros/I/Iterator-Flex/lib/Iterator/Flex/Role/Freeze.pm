package Iterator::Flex::Role::Freeze;

# ABSTRACT: Role to add serialization capability to an Iterator::Flex::Base

use strict;
use warnings;

our $VERSION = '0.19';

use List::Util;

use Iterator::Flex::Utils qw( :default ITERATOR :IterAttrs :RegistryKeys );
use Iterator::Flex::Base;
use Role::Tiny;
use experimental 'signatures';

use namespace::clean;










sub freeze ( $obj ) {

    my $ipar = $REGISTRY{ refaddr $obj }{ +ITERATOR };

    my @freeze;

    if ( defined $ipar->{ +_DEPENDS } ) {

        # first check if dependencies can freeze.
        my $cant = List::Util::first { !$_->can( 'freeze' ) }
        @{ $ipar->{ +_DEPENDS } };
        $obj->_throw( parameter => "dependency: @{[ $cant->_name ]} is not serializeable" )
          if $cant;

        # now freeze them
        @freeze = map $_->freeze, @{ $ipar->{ +_DEPENDS } };
    }

    push @freeze, $ipar->{ +FREEZE }->( $obj ), $obj->is_exhausted;

    return \@freeze;
}

requires 'is_exhausted';

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

Iterator::Flex::Role::Freeze - Role to add serialization capability to an Iterator::Flex::Base

=head1 VERSION

version 0.19

=head1 METHODS

=head2 freeze

  $freeze = $iter->freeze;

Returns a recipe to freeze an iterator and its dependencies.  See
L<Iterator::Flex/"Serialization of Iterators"> for more information.

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
