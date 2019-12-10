use strict;
use Test::More;

use GitHub::Apps::Auth;
use Crypt::PK::RSA;

my $pk = Crypt::PK::RSA->new->generate_key->export_key_pem("private");

my $auth = GitHub::Apps::Auth->new(
    private_key => \$pk,
    app_id => 42,
    installation_id => 4242,
);

$auth->token("1234567890");
$auth->expires(time() + 1_000_000_000);

is $auth, "1234567890";

my $joined_auth = "x-access-token:" . $auth;

is $auth, "1234567890";
is $joined_auth, "x-access-token:1234567890";
$joined_auth->token("abcdefghijk");
is $joined_auth, "x-access-token:abcdefghijk";
is $joined_auth . "\@github.com/owner/repo.git", "x-access-token:abcdefghijk\@github.com/owner/repo.git";

done_testing;
