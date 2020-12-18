use v5.10;
use strict;
use warnings;

package Meerkat::DateTime;
# ABSTRACT: DateTime proxy for lazy inflation from an epoch value

our $VERSION = '0.016';

use Moose 2;
use MooseX::AttributeShortcuts;
use MooseX::Storage;

use DateTime;
use namespace::autoclean;

with Storage;

#pod =attr epoch (required)
#pod
#pod Floating point epoch seconds
#pod
#pod =cut

has epoch => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);

#pod =attr DateTime
#pod
#pod A lazily-inflated DateTime object.  It will not be serialized by MooseX::Storage.
#pod
#pod =cut

has DateTime => (
    is     => 'lazy',
    isa    => 'DateTime',
    traits => ['DoNotSerialize'],
);

sub _build_DateTime {
    my ($self) = @_;
    return DateTime->from_epoch( epoch => $self->epoch );
}

__PACKAGE__->meta->make_immutable;

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Meerkat::DateTime - DateTime proxy for lazy inflation from an epoch value

=head1 VERSION

version 0.016

=head1 SYNOPSIS

  use Time::HiRes;
  use Meerkat::DateTime;

  my $mkdt = Meerkat::DateTime->new( epoch = time );
  my $datetime = $mkdt->DateTime;

=head1 DESCRIPTION

This module provides a way to lazily inflate floating point epoch seconds into
a L<DateTime> object.  It's conceptually similar to L<DateTime::Tiny>, but
without all the year, month, day, etc. fields.

The L<Meerkat::Types> module provides Moose type support and coercions and
L<MooseX::Storage> type handling to simplify having Meerkat::DateTime
attributes.

See the L<Meerkat::Cookbook> for more on handling dates and times.

=head1 ATTRIBUTES

=head2 epoch (required)

Floating point epoch seconds

=head2 DateTime

A lazily-inflated DateTime object.  It will not be serialized by MooseX::Storage.

=for Pod::Coverage method_names_here

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
