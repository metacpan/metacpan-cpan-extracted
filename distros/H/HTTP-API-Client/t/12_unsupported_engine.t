=head1 NAME

12_unsupported_engine.t - regression test for HAC-010: a custom engine
whose builder method exists and succeeds must still die with a clear
message from send(), instead of crashing confusingly later because the
response was never assigned

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    package CustomEngineClient;
    use Moo;
    extends 'HTTP::API::Client';
    has '+engine' => ( default => sub {'my_custom_ua'} );
    sub my_custom_ua { return bless {}, 'FakeUA' }
}

my $api = CustomEngineClient->new;

eval { $api->get("http://example.com") };
my $error = $@;

ok $error, "an engine other than LWP::UserAgent dies with a clear message from send()";
like $error, qr/my_custom_ua/, "the error names the offending engine";
unlike $error, qr/is_success/, "the error is not the confusing undef-response crash";

done_testing;
