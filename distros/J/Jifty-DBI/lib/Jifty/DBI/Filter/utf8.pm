
use strict;
use warnings;

package Jifty::DBI::Filter::utf8;
use base qw/Jifty::DBI::Filter/;
use Encode ();

=head1 NAME

Jifty::DBI::Filter::utf8 - Jifty::DBI UTF-8 data filter

=head1 DESCRIPTION

This filter allow you to check that you operate with
valid UTF-8 data.

Usage as type specific filter is recommended.

=head1 METHODS

=head2 encode

Method always unset UTF-8 flag on the value, but
if value doesn't have flag then method checks
value for malformed UTF-8 data and stop on
the first bad code.

=cut

sub encode {
    my $self = shift;

    my $value_ref = $self->value_ref;
    return undef unless ( defined($$value_ref) );

    if ( Encode::is_utf8($$value_ref) ) {
        $$value_ref = Encode::encode_utf8($$value_ref);
    } else {

        # if value has no utf8 flag but filter on the stack
        # we do double encoding, and stop on the first bad characters
        # with FB_QUIET fallback schema. We this schema because we
        # don't want data grow
        $$value_ref = Encode::encode_utf8(
            Encode::decode_utf8( $$value_ref, Encode::FB_QUIET ) );
    }
    return 1;
}

=head2 decode

Checks whether value is correct UTF-8 data or not and
substitute all malformed data with the C<0xFFFD> code point.

Always set UTF-8 flag on the value.

=cut

sub decode {
    my $self = shift;

    my $value_ref = $self->value_ref;
    return undef unless ( defined($$value_ref) );

    unless ( Encode::is_utf8($$value_ref) ) {
        $$value_ref = Encode::decode_utf8($$value_ref);
    }
    return 1;
}

1;
__END__

=head1 SEE ALSO

L<Jifty::DBI::Filter>, L<perlunicode>

=cut
