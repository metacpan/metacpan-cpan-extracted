use strict;
use Test::More;
use Test::Mock::Guard;

use GitHub::Apps::Auth;
use Crypt::PK::RSA;

my $pk = Crypt::PK::RSA->new->generate_key->export_key_pem("private");

my $g = mock_guard "GitHub::Apps::Auth" => {
    installations => sub {
        return {
            foobar => 4242,
        },
    },
};

my $auth = GitHub::Apps::Auth->new(
    private_key => \$pk,
    app_id => 42,
    login => "foobar",
);

is $auth->installation_id, 4242;

done_testing;
