package Google::Search::Partnerdataingestion::Logging::V1::Platformlog;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cj9nb29nbGUvc2VhcmNoL3BhcnRuZXJkYXRhaW5nZXN0aW9uL2xvZ2dpbmcvdjEvcGxhdGZv
cm1sb2cucHJvdG8SLWdvb2dsZS5zZWFyY2gucGFydG5lcmRhdGFpbmdlc3Rpb24ubG9nZ2lu
Zy52MSJgChBJbmdlc3REZXRhaWxzTG9nEjIKFWluZ2VzdGlvbl90cmFja2luZ19pZBgBIAEo
CVITaW5nZXN0aW9uVHJhY2tpbmdJZBIYCgdjb250ZW50GAIgASgJUgdjb250ZW50QqABCjFj
b20uZ29vZ2xlLnNlYXJjaC5wYXJ0bmVyZGF0YWluZ2VzdGlvbi5sb2dnaW5nLnYxQhBQbGF0
Zm9ybUxvZ1Byb3RvUAFaVGdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMv
c2VhcmNoL3BhcnRuZXJkYXRhaW5nZXN0aW9uL2xvZ2dpbmcvdjE7bG9nZ2luZ/gBAUriBwoG
EgQOAB8BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAA2CggK
AQgSAxIAHwoJCgIIHxIDEgAfCggKAQgSAxMAawoJCgIICxIDEwBrCggKAQgSAxQAIgoJCgII
ChIDFAAiCggKAQgSAxUAMQoJCgIICBIDFQAxCggKAQgSAxYASgoJCgIIARIDFgBKCjsKAgQA
EgQZAB8BGi8gTG9nIG1lc3NhZ2UgdXNlZCB0byBzZW5kIHRvIFBsYXRmb3JtIExvZ2dpbmcu
CgoKCgMEAAESAxkIGApDCgQEAAIAEgMbAiMaNiBJZGVudGlmaWNhdGlvbiBvZiB0aGUgc3Vj
Y2Vzc2Z1bGx5IGFjY2VwdGVkIHJlcXVlc3QuCgoMCgUEAAIABRIDGwIICgwKBQQAAgABEgMb
CR4KDAoFBAACAAMSAxshIgpECgQEAAIBEgMeAhUaNyBUaGUgbWVzc2FnZSBjb250ZW50IHdp
bGwgYmUgc2VudCB0byBQbGF0Zm9ybSBMb2dnaW5nLgoKDAoFBAACAQUSAx4CCAoMCgUEAAIB
ARIDHgkQCgwKBQQAAgEDEgMeExRiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Search::Partnerdataingestion::Logging::V1::Platformlog::IngestDetailsLog ===
    # Fields for IngestDetailsLog
    # Field: ingestion_tracking_id Type: 9 ()
    # Field: content Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Search::Partnerdataingestion::Logging::V1::Platformlog - Compiled Protocol Buffers messages for google/search/partnerdataingestion/logging/v1/platformlog.proto

=head1 SYNOPSIS

    use Google::Search::Partnerdataingestion::Logging::V1::Platformlog;

    my $msg = Google::Search::Partnerdataingestion::Logging::V1::Platformlog::IngestDetailsLog->new({
        ingestion_tracking_id => $ingestion_tracking_id,
        content => $content,
    });

    # Read or update a field
    my $val = $msg->ingestion_tracking_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Search::Partnerdataingestion::Logging::V1::Platformlog::IngestDetailsLog->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/search/partnerdataingestion/logging/v1/platformlog.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Search::Partnerdataingestion::Logging::V1::Platformlog::IngestDetailsLog

Log message used to send to Platform Logging.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ingestion_tracking_id() >> / C<< $msg->ingestion_tracking_id($value) >>

Type: C<String>

Identification of the successfully accepted request.

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<String>

The message content will be sent to Platform Logging.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Search::Partnerdataingestion::Logging::V1::Platformlog::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
