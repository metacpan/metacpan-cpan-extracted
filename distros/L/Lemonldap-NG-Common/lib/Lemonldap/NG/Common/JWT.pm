package Lemonldap::NG::Common::JWT;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK =
  qw(getAccessTokenSessionId getJWTHeader getJWTPayload getJWTSignature getJWTSignedData)
  ;    # symbols to export on request

use JSON;
use MIME::Base64 qw/encode_base64 decode_base64/;

our $VERSION = '2.0.12';

# Gets the Access Token session ID embedded in a LLNG-emitted JWT
sub getAccessTokenSessionId {
    my ($access_token) = @_;

    # Access Token is a JWT, extract the JTI field
    # and use it as session ID
    if ( index( $access_token, '.' ) > 0 ) {
        my $data = getJWTPayload($access_token);
        if ( $data and $data->{jti} ) {
            return $data->{jti};
        }
        else {
            return;
        }
    }

    # Access Token is the session ID directly
    else {
        return $access_token;
    }
}

# Isolate and decode parts of a JWT
# @param jwt in serialized form
# @param part 0 for header, 1 for payload, 2 for signature
# @param json whether or not to decode as JSON
# @return JSON string
sub getJWTPart {
    my ( $jwt, $part ) = @_;
    my @jwt_parts = split( /\./, $jwt );
    my $data      = decode_base64url( $jwt_parts[$part] );
    my $json_hash;
    eval { $json_hash = from_json($data); };
    return undef if ($@);
    return $json_hash;
}

# Return the JWT data that has to be signed by the OP
# @param jwt serialized JWT
# @return the string data to pass to the signature method
sub getJWTSignedData {
    my ($jwt) = @_;
    my @jwt_parts = split( /\./, $jwt );
    return ( $jwt_parts[0] . "." . $jwt_parts[1] );
}

# Convenience method to get the decoded JWT header
# @param jwt JWT in serialized form
# @return Perl hash
sub getJWTHeader {
    my ($jwt) = @_;
    return getJWTPart( $jwt, 0 );
}

# Convenience method to get the decoded JWT payload
# @param jwt JWT in serialized form
# @return Perl hash
sub getJWTPayload {
    my ($jwt) = @_;
    return getJWTPart( $jwt, 1 );
}

sub getJWTSignature {
    my ($jwt) = @_;
    my @jwt_parts = split( /\./, $jwt );
    return $jwt_parts[2];
}

sub decode_base64url {
    my $s = shift;
    $s =~ tr[-_][+/];
    $s .= '=' while length($s) % 4;
    return decode_base64($s);
}

1;
