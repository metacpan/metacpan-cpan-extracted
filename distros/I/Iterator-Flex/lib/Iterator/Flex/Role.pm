package Iterator::Flex::Role;

# ABSTRACT: Iterator Methods to add Iterator::Flex Iterator modifiers

use strict;
use warnings;

our $VERSION = '0.20';

use Role::Tiny;
use experimental 'signatures';

# avoid compile time dependency loop madness
require Iterator::Flex;

# the \&{...} nonsense below is to keep the prototype checker happy









sub icache ( $iter, $code, @args ) { Iterator::Flex::Common::icache( \&{$code}, $iter, @args ) }












sub igather ( $iter, $code, @args ) { Iterator::Flex::Common::igather( \&{$code}, $iter, @args ) }









sub igrep ( $iter, $code, @args ) { Iterator::Flex::Common::igrep( \&{$code}, $iter, @args ) }









sub imap ( $iter, $code, @args ) { Iterator::Flex::Common::imap( \&{$code}, $iter, @args ) }









sub ifreeze ( $iter, $code, @args ) { Iterator::Flex::Common::ifreeze( \&{$code}, $iter, @args ) }

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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory igather

=head1 NAME

Iterator::Flex::Role - Iterator Methods to add Iterator::Flex Iterator modifiers

=head1 VERSION

version 0.20

=head1 METHODS

=head2 icache

  $new_iter = $iter->icache( sub { ... } );

Return a new iterator caching the original iterator via L<Iterator::Flex/icache>.

=head2 igather

  $new_iter = $iter->igather( sub { ... } );

Return a new iterator modifying the original iterator via L<Iterator::Flex/igather>.

=head2 igrep

  $new_iter = $iter->igrep( sub { ... } );

Return a new iterator modifying the original iterator via L<Iterator::Flex/igrep>.

=head2 imap

  $new_iter = $iter->imap( sub { ... } );

Return a new iterator modifying the original iterator via L<Iterator::Flex/ifreeze>.

=head2 ifreeze

  $new_iter = $iter->ifreeze( sub { ... } );

Return a new iterator modifying the original iterator via L<Iterator::Flex/ifreeze>.

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
