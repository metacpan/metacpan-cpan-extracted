package HTTP::Session2::Random;
use strict;
use warnings;
use utf8;
use 5.008_001;

# DO NOT USE THIS DIRECTLY.

use MIME::Base64 ();
use Digest::SHA ();
use Time::HiRes;

our $URANDOM_FH;

# $URANDOM_FH is undef if there is no /dev/urandom
open $URANDOM_FH, '<:raw', '/dev/urandom'
    or do {
    undef $URANDOM_FH;
    warn "Cannot open /dev/urandom: $!.";
};

sub generate_session_id {
    if ($URANDOM_FH) {
        my $length = 24;
        # Generate session id from /dev/urandom.
        my $read = read($URANDOM_FH, my $buf, $length);
        if ($read != $length) {
            die "Cannot read bytes from /dev/urandom: $!";
        }
        my $result = MIME::Base64::encode_base64($buf, '');
        $result =~ tr|+/=|\-_|d; # make it url safe
        return substr($result, 0, 31);
    } else {
        # It's weaker than above. But it's portable.
        substr(Digest::SHA::sha1_hex(rand() . $$ . {} . Time::HiRes::time()),int(rand(4)),31);
    }
}

1;
