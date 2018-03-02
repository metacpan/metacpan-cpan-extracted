use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = "LibreCat::Auth::SSO::ResponseParser::ORCID";
    use_ok $pkg;
}
require_ok $pkg;

my $json = <<EOF;
{
    "access_token": "89f0181c-168b-4d7d-831c-1fdda2d7bbbb",
    "token_type": "bearer",
    "refresh_token": "69e883f6-d84e-4ae6-87f5-ef0044e3e9a7",
    "expires_in": 631138518,
    "scope": "/authenticate",
    "orcid": "0000-0001-2345-6789",
    "name":"Sofia Garcia"
}
EOF
my $hash = +{
    uid => "0000-0001-2345-6789",
    info => {
        name => "Sofia Garcia"
    },
    extra => {
        access_token => "89f0181c-168b-4d7d-831c-1fdda2d7bbbb",
        token_type => "bearer",
        refresh_token => "69e883f6-d84e-4ae6-87f5-ef0044e3e9a7",
        expires_in => 631138518,
        scope => "/authenticate"
    }
};

is_deeply(
    $pkg->new()->parse( $json ),
    $hash,
    "cas:serviceResponse"
);

done_testing;
