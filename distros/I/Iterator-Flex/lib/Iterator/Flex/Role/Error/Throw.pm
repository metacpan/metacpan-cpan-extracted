package Iterator::Flex::Role::Error::Throw;

# ABSTRACT: signal error by throwing

use strict;
use warnings;

our $VERSION = '0.19';

use Iterator::Flex::Utils qw( :default :RegistryKeys );
use Ref::Util;

use Role::Tiny;
use experimental 'signatures';

use namespace::clean;











sub signal_error ( $self ) {
    $self->set_error;
    my $exception = $REGISTRY{ refaddr $self }{ +GENERAL }{ +ERROR }[1];

    $exception->() if Ref::Util::is_coderef( $exception );

    require Iterator::Flex::Failure;
    Iterator::Flex::Failure::Error->throw;
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

Iterator::Flex::Role::Error::Throw - signal error by throwing

=head1 VERSION

version 0.19

=head1 METHODS

=head2 signal_error

   $iterator->signal_error;

Signal that an error occurred.  This version sets the
iterator's error flag and throws an exception.

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
