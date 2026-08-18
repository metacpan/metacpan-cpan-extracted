=head1 NAME

17_kvp_nested_hash.t - regression test for HAC-020: a nested hash value in
form-urlencoded mode must die with a clear message naming the key, instead
of silently stringifying as 'HASH(0x...)' in the URL

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );

eval {
    $api->get( "http://example.com",
        { user => { name => "bob", age => 30 } },
        {}, { test_request_object => 1 } );
};
my $error = $@;

ok $error, "a nested hash value dies instead of silently producing garbage";
like $error, qr/user/, "the error names the offending key";

done_testing;
