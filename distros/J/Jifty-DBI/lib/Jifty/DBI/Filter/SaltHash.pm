package Jifty::DBI::Filter::SaltHash;

use warnings;
use strict;

use base qw|Jifty::DBI::Filter|;
use Digest::MD5 qw(md5_hex);

=head1 NAME

Jifty::DBI::Filter::SaltHash - salts and hashes a value before storing it

=head1 DESCRIPTION

This filter will generate a random 4-byte salt, and then MD5 the given
value with the salt appended to the value. It will store the hash and
the salt in the database, and return a data structure that contains
both on decode. The salt and hash are stored in hexadecimal in the
database, so that you can put them in a text field.

This filter is intended for storing passwords in a database.

=head2 encode

Generate a random 4-byte salt, MD5 the value with the salt (encoded to
hexadecimal) appended to it, and store both in the database.

=cut

sub encode {
    my $self = shift;
    my $value_ref = $self->value_ref;

    return unless defined $$value_ref;

    my $salt = generate_salt();

    $$value_ref = md5_hex($$value_ref, $salt) . $salt;
}

=head2 generate_salt

Return a random 4-byte salt value, encoded as an 8-character hex
string.

=cut

sub generate_salt {
    my $salt;
    $salt .= unpack('H2',chr(int rand(255))) for(1..4);
    return $salt;
}

=head2 decode

Return an arrayref of (hash, salt), both as hex strings.

To test whether a provided value is the same one originally encoded,
use

    $hash eq md5_hex($value . $salt);

=cut

sub decode {
    my $self = shift;
    my $value_ref = $self->value_ref;

    return unless $$value_ref;

    # This should never happen, but just to be safe
    unless(length($$value_ref) == (8 + 32)) {
        $$value_ref = [undef, undef];
    } else {
        $$value_ref = [unpack("A32A8", $$value_ref)];
    }

    return 1;
}



=head1 SEE ALSO

L<Jifty::DBI::Filter>, L<Digest::MD5>

=cut

1;
