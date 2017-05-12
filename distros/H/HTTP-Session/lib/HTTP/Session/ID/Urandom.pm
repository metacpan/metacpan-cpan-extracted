package HTTP::Session::ID::Urandom;
use strict;
use warnings;
use utf8;
use 5.008_001;
use MIME::Base64;
use POSIX;

our $URANDOM_FH;

# $URANDOM_FH is undef if there is no /dev/urandom
open $URANDOM_FH, '<:raw', '/dev/urandom'
    or die "Cannot open /dev/urandom: $!.";

sub generate_id {
    my ($class, $sid_length) = @_;
    my $src_len = POSIX::ceil($sid_length/3.0*4.0);
    # Generate session id from /dev/urandom.
    my $read = read($URANDOM_FH, my $buf, $src_len);
    if ($read != $src_len) {
        die "Cannot read bytes from /dev/urandom: $!";
    }
    my $result = MIME::Base64::encode_base64($buf, '');
    $result =~ tr|+/=|\-_|d; # make it url safe
    return substr($result, 0, $sid_length);
}

1;

