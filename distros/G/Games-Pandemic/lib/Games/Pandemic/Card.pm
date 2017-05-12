#
# This file is part of Games-Pandemic
#
# This software is Copyright (c) 2009 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 2, June 1991
#
use 5.010;
use strict;
use warnings;

package Games::Pandemic::Card;
{
  $Games::Pandemic::Card::VERSION = '1.120510';
}
# ABSTRACT: base class for pandemic cards

use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;


# -- builders / finishers

sub DEMOLISH {
    my $self = shift;
    #debug( "~card: " . $self->label . "\n" );
}


# -- accessors

has label => ( is => 'ro', isa => 'Str', lazy_build => 1 );
has icon  => ( is => 'ro', isa => 'Str', lazy_build => 1 );

no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Card - base class for pandemic cards

=head1 VERSION

version 1.120510

=for Pod::Coverage DEMOLISH

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__

