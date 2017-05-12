#!/usr/bin/env perl
package Jifty::DBI::Filter::URI;
use strict;
use warnings;

use base 'Jifty::DBI::Filter';
use URI;

=head1 NAME

Jifty::DBI::Filter::URI - Encodes uniform resource identifiers

=head1 DESCRIPTION

=head2 encode

If the value is a L<URI>, encode it to its string
form. Otherwise, do nothing.

=cut

sub encode {
    my $self = shift;

    my $value_ref = $self->value_ref;
    return unless ref $$value_ref and $$value_ref->isa('URI');

    $$value_ref = $$value_ref->as_string;
    return 1;
}

=head2 decode

If value is defined, then decode it using
L<URI/as_string>, otherwise do nothing.

=cut

sub decode {
    my $self = shift;

    my $value_ref = $self->value_ref;
    return unless defined $$value_ref and length $$value_ref;

    $$value_ref = URI->new($$value_ref);
}

=head1 SEE ALSO

L<Jifty::DBI::Filter>, L<URI>

=cut

1;

