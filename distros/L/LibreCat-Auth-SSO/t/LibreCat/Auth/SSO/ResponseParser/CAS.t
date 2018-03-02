use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = "LibreCat::Auth::SSO::ResponseParser::CAS";
    use_ok $pkg;
}
require_ok $pkg;

my $xml = <<EOF;
<?xml version="1.0"?>
<cas:serviceResponse xmlns:cas="http://www.yale.edu/tp/cas">
    <cas:authenticationSuccess>
        <cas:user>username</cas:user>
        <cas:attributes>
            <cas:firstname>John</cas:firstname>
            <cas:lastname>Doe</cas:lastname>
            <cas:title>Mr.</cas:title>
            <cas:email>jdoe\@example.org</cas:email>
            <cas:affiliation>staff</cas:affiliation>
            <cas:affiliation>faculty</cas:affiliation>
        </cas:attributes>
        <cas:proxyGrantingTicket>PGTIOU-84678-8a9d...</cas:proxyGrantingTicket>
    </cas:authenticationSuccess>
</cas:serviceResponse>
EOF

is_deeply(
    $pkg->new()->parse( $xml ),
    +{
        uid => "username",
        info => {
            firstname => "John",
            lastname => "Doe",
            title => "Mr.",
            email => "jdoe\@example.org",
            affiliation => ["staff","faculty"]
        },
        extra => {}
    },
    "cas:serviceResponse"
);

done_testing;
