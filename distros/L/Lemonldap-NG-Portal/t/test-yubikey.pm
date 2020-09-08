use LWP::Protocol::PSGI;
use MIME::Base64;
use Digest::HMAC_SHA1 qw(hmac_sha1 hmac_sha1_hex);

# Fake yubikeyserver will succed for any OTP whose unique partbegins with 1
# and fail when it begins with 2
# eg of valid OTP
#  cccccccccccc 10000000000000000000
#  ^            ^
#   \-token ID   \- time-dependant code
#
my $fake_yubikey_server = sub {
    my $req    = Plack::Request->new(@_);
    my $otp    = $req->parameters->{otp};
    my $nonce  = $req->parameters->{nonce};
    my $id     = substr $otp, 0, 12;
    my $unique = substr $otp, 12;
    my $status;

    if ( $unique =~ /^1/ ) {
        $status = "OK";
    }

    if ( $unique =~ /^2/ ) {
        $status = "BAD_OTP";
    }

    my %res_without_hash = (
        status => $status,
        nonce  => $nonce,
        otp    => $otp,
    );

    my $str = join '&',
      map { $_ . "=" . $res_without_hash{$_} } sort keys(%res_without_hash);
    my $hmac =
      encode_base64( hmac_sha1( $str, decode_base64("cG9uZXk=") ), '' );
    my %res = ( %res_without_hash, h => $hmac );

    my $bytes = join "\r\n", map { $_ . "=" . $res{$_} } keys(%res);
    return [ 200, [], [$bytes] ];

};

LWP::Protocol::PSGI->register($fake_yubikey_server);

1;
