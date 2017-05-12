package Jifty::DBI::Filter::Storable;

use warnings;
use strict;

use base qw|Jifty::DBI::Filter|;
use Storable ();

=head1 NAME

Jifty::DBI::Filter::Storable - Encodes arbitrary data using Storable

=head1 DESCRIPTION

This filter allows you to store arbitrary Perl data structures in a
column of type 'blob', using L<Storable> to serialize them.

=head2 encode

If value is defined, then encodes it using L<Storable/nfreeze>. Does
nothing if value is not defined.

=cut

sub encode {
    my $self = shift;

    my $value_ref = $self->value_ref;
    return unless defined $$value_ref;

    $Storable::Deparse = 1;
    $$value_ref = Storable::nfreeze($value_ref);
}

=head2 decode

If value is defined, then decodes it using L<Storable/thaw>, otherwise
does nothing.

=cut

sub decode {
    my $self = shift;

    my $value_ref = $self->value_ref;
    return unless defined $$value_ref;

    # Storable doesn't take Unicode strings.
    Encode::_utf8_off($$value_ref);

    local $@;
    $Storable::Eval = 1;
    $$value_ref = eval { ${ Storable::thaw($$value_ref) } };
}

=head1 SEE ALSO

L<Jifty::DBI::Filter>, L<Storable>

=cut

1;
