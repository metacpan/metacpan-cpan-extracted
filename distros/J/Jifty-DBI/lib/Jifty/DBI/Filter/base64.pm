package Jifty::DBI::Filter::base64;

use warnings;
use strict;

use base qw|Jifty::DBI::Filter|;
use Encode qw(encode_utf8 is_utf8);
use MIME::Base64 ();

=head1 NAME

Jifty::DBI::Filter::base64 - Encodes data as base64

=head1 DESCRIPTION

This filter allow you to store arbitrary data in a column of type
'text'.

=head2 encode

If value is defined, then encodes it using L<MIME::Base64/encode_base64> after
passing it through L<Encode/encode_utf8>.  Does nothing if value is not
defined.

=cut

sub encode {
    my $self = shift;

    my $value_ref = $self->value_ref;
    return unless defined $$value_ref;

    $$value_ref = MIME::Base64::encode_base64(
        is_utf8($$value_ref) ? encode_utf8($$value_ref) : $$value_ref
    );

    return 1;
}

=head2 decode

If value is defined, then decodes it using
L<MIME::Base64/decode_base64>, otherwise do nothing.

=cut

sub decode {
    my $self = shift;

    my $value_ref = $self->value_ref;
    return unless defined $$value_ref;

    $$value_ref = MIME::Base64::decode_base64($$value_ref);
}

=head1 SEE ALSO

L<Jifty::DBI::Filter>, L<MIME::Base64>

=cut

1;
