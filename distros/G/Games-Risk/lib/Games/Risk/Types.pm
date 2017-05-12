#
# This file is part of Games-Risk
#
# This software is Copyright (c) 2008 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.010;
use strict;
use warnings;

package Games::Risk::Types;
# ABSTRACT: various types used in the distribution
$Games::Risk::Types::VERSION = '4.000';
use Moose::Util::TypeConstraints;

enum CardType   => [qw{ artillery cavalry infantry joker }];
enum PlayerType => [qw{ human ai }];

1;

__END__

=pod

=head1 NAME

Games::Risk::Types - various types used in the distribution

=head1 VERSION

version 4.000

=head1 DESCRIPTION

This module defines and exports the types used by other modules of the
distribution.

The exported types are:

=over 4

=item CardType - the type of the card.

=item PlayerType - the type of the player.

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
