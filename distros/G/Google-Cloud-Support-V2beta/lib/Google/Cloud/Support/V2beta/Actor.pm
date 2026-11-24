package Google::Cloud::Support::V2beta::Actor;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvc3VwcG9ydC92MmJldGEvYWN0b3IucHJvdG8SG2dvb2dsZS5jbG91
ZC5zdXBwb3J0LnYyYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byKRAQoF
QWN0b3ISIQoMZGlzcGxheV9uYW1lGAEgASgJUgtkaXNwbGF5TmFtZRIYCgVlbWFpbBgCIAEo
CUICGAFSBWVtYWlsEioKDmdvb2dsZV9zdXBwb3J0GAQgASgIQgPgQQNSDWdvb2dsZVN1cHBv
cnQSHwoIdXNlcm5hbWUYBSABKAlCA+BBA1IIdXNlcm5hbWVCxwEKH2NvbS5nb29nbGUuY2xv
dWQuc3VwcG9ydC52MmJldGFCCkFjdG9yUHJvdG9QAVo5Y2xvdWQuZ29vZ2xlLmNvbS9nby9z
dXBwb3J0L2FwaXYyYmV0YS9zdXBwb3J0cGI7c3VwcG9ydHBiqgIbR29vZ2xlLkNsb3VkLlN1
cHBvcnQuVjJCZXRhygIbR29vZ2xlXENsb3VkXFN1cHBvcnRcVjJiZXRh6gIeR29vZ2xlOjpD
bG91ZDo6U3VwcG9ydDo6VjJiZXRhSrERCgYSBA4ANwEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQACQKCQoCAwASAxIAKQoICgEIEgMUADgKCQoCCCUSAxQA
OAoICgEIEgMVAFAKCQoCCAsSAxUAUAoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXACsK
CQoCCAgSAxcAKwoICgEIEgMYADgKCQoCCAESAxgAOAoICgEIEgMZADgKCQoCCCkSAxkAOAoI
CgEIEgMaADcKCQoCCC0SAxoANwrrAQoCBAASBB8ANwEa3gEgQW4gQWN0b3IgcmVwcmVzZW50
cyBhbiBlbnRpdHkgdGhhdCBwZXJmb3JtZWQgYW4gYWN0aW9uLiBGb3IgZXhhbXBsZSwgYW4g
YWN0b3IKIGNvdWxkIGJlIGEgdXNlciB3aG8gcG9zdGVkIGEgY29tbWVudCBvbiBhIHN1cHBv
cnQgY2FzZSwgYSB1c2VyIHdobwogdXBsb2FkZWQgYW4gYXR0YWNobWVudCwgb3IgYSBzZXJ2
aWNlIGFjY291bnQgdGhhdCBjcmVhdGVkIGEgc3VwcG9ydCBjYXNlLgoKCgoDBAABEgMfCA0K
hQIKBAQAAgASAyQCGhr3ASBUaGUgbmFtZSB0byBkaXNwbGF5IGZvciB0aGUgYWN0b3IuIElm
IG5vdCBwcm92aWRlZCwgaXQgaXMgaW5mZXJyZWQgZnJvbQogY3JlZGVudGlhbHMgc3VwcGxp
ZWQgZHVyaW5nIGNhc2UgY3JlYXRpb24uIFdoZW4gYW4gZW1haWwgaXMgcHJvdmlkZWQsIGEK
IGRpc3BsYXkgbmFtZSBtdXN0IGFsc28gYmUgcHJvdmlkZWQuIFRoaXMgd2lsbCBiZSBvYmZ1
c2NhdGVkIGlmIHRoZSB1c2VyCiBpcyBhIEdvb2dsZSBTdXBwb3J0IGFnZW50LgoKDAoFBAAC
AAUSAyQCCAoMCgUEAAIAARIDJAkVCgwKBQQAAgADEgMkGBkKrgIKBAQAAgESAywCJxqgAiBU
aGUgZW1haWwgYWRkcmVzcyBvZiB0aGUgYWN0b3IuIElmIG5vdCBwcm92aWRlZCwgaXQgaXMg
aW5mZXJyZWQgZnJvbSB0aGUKIGNyZWRlbnRpYWxzIHN1cHBsaWVkIGR1cmluZyBjYXNlIGNy
ZWF0aW9uLiBXaGVuIGEgbmFtZSBpcyBwcm92aWRlZCwgYW4KIGVtYWlsIG11c3QgYWxzbyBi
ZSBwcm92aWRlZC4gSWYgdGhlIHVzZXIgaXMgYSBHb29nbGUgU3VwcG9ydCBhZ2VudCwgdGhp
cyBpcwogb2JmdXNjYXRlZC4KCiBUaGlzIGZpZWxkIGlzIGRlcHJlY2F0ZWQuIFVzZSBgdXNl
cm5hbWVgIGluc3RlYWQuCgoMCgUEAAIBBRIDLAIICgwKBQQAAgEBEgMsCQ4KDAoFBAACAQMS
AywREgoMCgUEAAIBCBIDLBMmCg0KBgQAAgEIAxIDLBQlCkgKBAQAAgISAy8CRho7IE91dHB1
dCBvbmx5LiBXaGV0aGVyIHRoZSBhY3RvciBpcyBhIEdvb2dsZSBzdXBwb3J0IGFjdG9yLgoK
DAoFBAACAgUSAy8CBgoMCgUEAAICARIDLwcVCgwKBQQAAgIDEgMvGBkKDAoFBAACAggSAy8a
RQoPCggEAAICCJwIABIDLxtECr8CCgQEAAIDEgM2AkIasQIgT3V0cHV0IG9ubHkuIFRoZSB1
c2VybmFtZSBvZiB0aGUgYWN0b3IuIEl0IG1heSBsb29rIGxpa2UgYW4gZW1haWwgb3Igb3Ro
ZXIKIGZvcm1hdCBwcm92aWRlZCBieSB0aGUgaWRlbnRpdHkgcHJvdmlkZXIuIElmIG5vdCBw
cm92aWRlZCwgaXQgaXMgaW5mZXJyZWQKIGZyb20gdGhlIGNyZWRlbnRpYWxzIHN1cHBsaWVk
LiBXaGVuIGEgbmFtZSBpcyBwcm92aWRlZCwgYSB1c2VybmFtZSBtdXN0CiBhbHNvIGJlIHBy
b3ZpZGVkLiBJZiB0aGUgdXNlciBpcyBhIEdvb2dsZSBTdXBwb3J0IGFnZW50LCB0aGlzIHdp
bGwgbm90IGJlCiBzZXQuCgoMCgUEAAIDBRIDNgIICgwKBQQAAgMBEgM2CREKDAoFBAACAwMS
AzYUFQoMCgUEAAIDCBIDNhZBCg8KCAQAAgMInAgAEgM2F0BiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2beta::Actor::Actor ===
    # Fields for Actor
    # Field: display_name Type: 9 ()
    # Field: email Type: 9 ()
    # Field: google_support Type: 8 ()
    # Field: username Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2beta::Actor - Compiled Protocol Buffers messages for google/cloud/support/v2beta/actor.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2beta::Actor;

    my $msg = Google::Cloud::Support::V2beta::Actor::Actor->new({
        display_name => $display_name,
        email => $email,
        google_support => $google_support,
        username => $username,
    });

    # Read or update a field
    my $val = $msg->display_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2beta::Actor::Actor->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2beta/actor.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2beta::Actor::Actor

An Actor represents an entity that performed an action. For example, an actor
could be a user who posted a comment on a support case, a user who
uploaded an attachment, or a service account that created a support case.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The name to display for the actor. If not provided, it is inferred from
credentials supplied during case creation. When an email is provided, a
display name must also be provided. This will be obfuscated if the user
is a Google Support agent.

=item * C<< $msg->email() >> / C<< $msg->email($value) >>

Type: C<String>

The email address of the actor. If not provided, it is inferred from the
credentials supplied during case creation. When a name is provided, an
email must also be provided. If the user is a Google Support agent, this is
obfuscated.

This field is deprecated. Use `username` instead.

=item * C<< $msg->google_support() >> / C<< $msg->google_support($value) >>

Type: C<Bool>

Output only. Whether the actor is a Google support actor.

=item * C<< $msg->username() >> / C<< $msg->username($value) >>

Type: C<String>

Output only. The username of the actor. It may look like an email or other
format provided by the identity provider. If not provided, it is inferred
from the credentials supplied. When a name is provided, a username must
also be provided. If the user is a Google Support agent, this will not be
set.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2beta::Actor::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
