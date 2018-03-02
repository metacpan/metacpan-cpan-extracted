use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = "LibreCat::Auth::SSO::CAS";
    use_ok $pkg;
}
require_ok $pkg;

dies_ok(
    sub {
        $pkg->new();
    },
    "cas_url required"
);
lives_ok(
    sub {
        $pkg->new( cas_url => "https://localhost:8443/cas" );
    },
    "lives ok"
);

done_testing;
