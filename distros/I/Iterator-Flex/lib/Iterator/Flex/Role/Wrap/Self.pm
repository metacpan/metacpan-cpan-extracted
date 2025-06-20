package Iterator::Flex::Role::Wrap::Self;

# ABSTRACT: Construct a next() method for a coderef which expects to be passed an object ref

# is this actually used?

use strict;
use warnings;

our $VERSION = '0.19';

use Scalar::Util;
use Iterator::Flex::Utils 'NEXT';

use Role::Tiny;
use experimental 'signatures';

use namespace::clean;

sub _construct_next ( $, $ipar, $ ) {

    # ensure we don't hold any strong references in the subroutine
    my $next = $ipar->{ +NEXT };
    Scalar::Util::weaken $next;

    my $sub;
    $sub = sub { $next->( $sub ) };

    # create a second reference to the subroutine before we weaken $sub,
    # otherwise $sub will lose its contents, as it would be the only
    # reference.
    my $rsub = $sub;
    Scalar::Util::weaken( $sub );
    return $rsub;
}

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

Iterator::Flex::Role::Wrap::Self - Construct a next() method for a coderef which expects to be passed an object ref

=head1 VERSION

version 0.19

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
