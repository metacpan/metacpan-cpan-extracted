package Google::Appengine::V1::Domain;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiBnb29nbGUvYXBwZW5naW5lL3YxL2RvbWFpbi5wcm90bxITZ29vZ2xlLmFwcGVuZ2luZS52
MSI2ChBBdXRob3JpemVkRG9tYWluEhIKBG5hbWUYASABKAlSBG5hbWUSDgoCaWQYAiABKAlS
AmlkQrwBChdjb20uZ29vZ2xlLmFwcGVuZ2luZS52MUILRG9tYWluUHJvdG9QAVo7Y2xvdWQu
Z29vZ2xlLmNvbS9nby9hcHBlbmdpbmUvYXBpdjEvYXBwZW5naW5lcGI7YXBwZW5naW5lcGKq
AhlHb29nbGUuQ2xvdWQuQXBwRW5naW5lLlYxygIZR29vZ2xlXENsb3VkXEFwcEVuZ2luZVxW
MeoCHEdvb2dsZTo6Q2xvdWQ6OkFwcEVuZ2luZTo6VjFK+wkKBhIEDgAnAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHAoICgEIEgMSADYKCQoCCCUSAxIA
NgoICgEIEgMTAFIKCQoCCAsSAxMAUgoICgEIEgMUACIKCQoCCAoSAxQAIgoICgEIEgMVACwK
CQoCCAgSAxUALAoICgEIEgMWADAKCQoCCAESAxYAMAoICgEIEgMXADYKCQoCCCkSAxcANgoI
CgEIEgMYADUKCQoCCC0SAxgANQq/AQoCBAASBB0AJwEasgEgQSBkb21haW4gdGhhdCBhIHVz
ZXIgaGFzIGJlZW4gYXV0aG9yaXplZCB0byBhZG1pbmlzdGVyLiBUbyBhdXRob3JpemUgdXNl
CiBvZiBhIGRvbWFpbiwgdmVyaWZ5IG93bmVyc2hpcCB2aWEKIFtTZWFyY2ggQ29uc29sZV0o
aHR0cHM6Ly9zZWFyY2guZ29vZ2xlLmNvbS9zZWFyY2gtY29uc29sZS93ZWxjb21lKS4KCgoK
AwQAARIDHQgYCosBCgQEAAIAEgMiAhIafiBGdWxsIHBhdGggdG8gdGhlIGBBdXRob3JpemVk
RG9tYWluYCByZXNvdXJjZSBpbiB0aGUgQVBJLiBFeGFtcGxlOgogYGFwcHMvbXlhcHAvYXV0
aG9yaXplZERvbWFpbnMvZXhhbXBsZS5jb21gLgoKIEBPdXRwdXRPbmx5CgoMCgUEAAIABRID
IgIICgwKBQQAAgABEgMiCQ0KDAoFBAACAAMSAyIQEQplCgQEAAIBEgMmAhAaWCBGdWxseSBx
dWFsaWZpZWQgZG9tYWluIG5hbWUgb2YgdGhlIGRvbWFpbiBhdXRob3JpemVkIGZvciB1c2Uu
IEV4YW1wbGU6CiBgZXhhbXBsZS5jb21gLgoKDAoFBAACAQUSAyYCCAoMCgUEAAIBARIDJgkL
CgwKBQQAAgEDEgMmDg9iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1::Domain::AuthorizedDomain ===
    # Fields for AuthorizedDomain
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1::Domain - Compiled Protocol Buffers messages for google/appengine/v1/domain.proto

=head1 SYNOPSIS

    use Google::Appengine::V1::Domain;

    my $msg = Google::Appengine::V1::Domain::AuthorizedDomain->new({
        name => $name,
        id => $id,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1::Domain::AuthorizedDomain->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1/domain.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1::Domain::AuthorizedDomain

A domain that a user has been authorized to administer. To authorize use
of a domain, verify ownership via
[Search Console](https://search.google.com/search-console/welcome).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Full path to the `AuthorizedDomain` resource in the API. Example:
`apps/myapp/authorizedDomains/example.com`.

@OutputOnly

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Fully qualified domain name of the domain authorized for use. Example:
`example.com`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1::Domain::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
