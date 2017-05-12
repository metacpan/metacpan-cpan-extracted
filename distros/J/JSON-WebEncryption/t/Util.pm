package t::Util;

use strict;
use warnings;
use Test::More;
use Exporter 'import';

use JSON::WebEncryption;

our @EXPORT = qw(test_encode_decode test_encode_decode_object);

sub test_encode_decode {
    my %specs = @_;
    my ($desc, $input, $expects_exception) =
        @specs{qw/desc input expects_exception/};

    my ($plaintext, $encoding, $public_key, $private_key, $secret, $algorithm, $extra_headers) =
        @$input{qw/plaintext encoding public_key private_key secret algorithm extra_headers/};
    $public_key  ||= $secret;
    $private_key ||= $secret;

    my $test = sub {
        my $jwe = encode_jwe $plaintext, $encoding, $public_key, $algorithm, $extra_headers;
        note "jwe: $jwe";
        return decode_jwe $jwe, $private_key;
    };
    subtest $desc => sub {
        unless ($expects_exception) {
            my $got = $test->();
            is_deeply $got, $plaintext;
        }
        else {
            eval { $test->() };
            like $@, qr/$expects_exception/;
        }
    };
}

sub test_encode_decode_object {
    my %specs = @_;
    my ($desc, $input, $expects_exception) =
        @specs{qw/desc input expects_exception/};

    my ($plaintext, $encoding, $public_key, $private_key, $secret, $algorithm, $extra_headers) =
        @$input{qw/plaintext encoding public_key private_key secret algorithm extra_headers/};
    $public_key  ||= $secret;
    $private_key ||= $secret;

    my $test = sub {
        my $jwe_obj = new JSON::WebEncryption(
                enc => $encoding,
                alg => $algorithm,
                key => $secret,
                public_key => $public_key,
                private_key => $private_key );

        my $jwe = $jwe_obj->encode( $plaintext );
        note "jwe: $jwe";
        return $jwe_obj->decode( $jwe );
    };
    subtest $desc => sub {
        unless ($expects_exception) {
            my $got = $test->();
            is_deeply $got, $plaintext;
        }
        else {
            eval { $test->() };
            like $@, qr/$expects_exception/;
        }
    };
}

1;
__END__
