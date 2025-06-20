package Iterator::Flex::Role::Next::ClosedSelf;

# ABSTRACT: Role for closure iterator which closes over self

use strict;
use warnings;

our $VERSION = '0.19';

use Ref::Util;
use Scalar::Util;
use Iterator::Flex::Utils qw( NEXT _SELF );

use Role::Tiny;
use experimental 'signatures';
use namespace::clean;









sub _construct_next ( $class, $ipar, $ ) {

    my $sub = $ipar->{ +NEXT } // $class->_throw( parameter => "Missing 'next' parameter" );
    Scalar::Util::weaken $ipar->{ +NEXT };

    $class->_throw( parameter => "Missing ability to set self" )
      unless exists $ipar->{ +_SELF };

    my $ref = $ipar->{ +_SELF };
    $$ref = $sub;
    Scalar::Util::weaken $$ref;
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

Iterator::Flex::Role::Next::ClosedSelf - Role for closure iterator which closes over self

=head1 VERSION

version 0.19

=head1 METHODS

=head2 next

=head2 __next__

   $iterator->next;

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
