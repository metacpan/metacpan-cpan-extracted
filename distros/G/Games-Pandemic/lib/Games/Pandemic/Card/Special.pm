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

package Games::Pandemic::Card::Special;
{
  $Games::Pandemic::Card::Special::VERSION = '1.120510';
}
# ABSTRACT: base class for special pandemic event cards

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Games::Pandemic::Card';

has description => ( is => 'ro', isa => 'Str', lazy_build => 1 );


# -- public methods



sub event {
    my $self = shift;
    my $ref  = ref $self;
    $ref =~ s/^Games::Pandemic::Card::Special:://;
    $ref =~ s/([[:upper:]])/_$1/g;
    $ref =~ s/^_//;
    return lc $ref;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Card::Special - base class for special pandemic event cards

=head1 VERSION

version 1.120510

=head1 DESCRIPTION

This package is the base class for all special event cards in
L<Games::Pandemic>. Nothing really interesting, check the
subclasses instead.

=head1 METHODS

=head2 my $event = $special->event;

Return the special card name, from C<CamelCaseName> to
C<camel_case_name>. This will be used as the event name sent to
main window.

Eg, L<Games::Pandemic::Card::Special::OneQuietNight> objects will return
C<one_quiet_night>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__


