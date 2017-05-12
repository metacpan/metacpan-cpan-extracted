use strict;
use warnings;
use utf8;

use Test::More tests => 52;
use Encode;
use MIME::Base64 qw/encode_base64/;
use Kernel::Keyring;

use constant PERM => 0x3f000000;

BEGIN {
    eval { require Crypt::URandom };
    if ($@) {
        *main::urandom = sub {
            my $bytes = $_[0];
            local $/ = \$bytes;
            open my $fh, '<', '/dev/urandom' or die $!;
            my $str = <$fh>;
            close $fh or warn $!;
            return $str;
        }
    }
    else {
        *main::urandom = \&Crypt::URandom::urandom;
    }
}

key_session 'KeePass4Web-Tests';

sub test_keyring {
    my $data = shift;

    my $id = key_add 'user', int rand 2**32, $data, '@s';

    key_timeout $id, 60;
    key_perm $id, PERM;

    my $data_retrieved = key_get_by_id $id;
    key_revoke $id;
    key_unlink $id, '@s';

    return $data_retrieved;
}

for (1..50) {
    my $data = urandom(32);
    my $data_retrieved = test_keyring $data;

    ok $data eq $data_retrieved, "roundtrip random $_: '" . encode_base64($data, '') . "' eq '" . encode_base64($data_retrieved, '') . "'";
}

my $data = "some string \0 some more \0\0\0 even more";
my $data_retrieved = test_keyring $data;

ok $data eq $data_retrieved, "roundtrip nul bytes: '$data' eq '$data_retrieved'";

$data = Encode::encode 'UTF-8', '中文字 русский язык ❤✓☀★☂ öäüß';
$data_retrieved = test_keyring $data;

ok $data eq $data_retrieved, "roundtrip unicode: '$data' eq '$data_retrieved'";

