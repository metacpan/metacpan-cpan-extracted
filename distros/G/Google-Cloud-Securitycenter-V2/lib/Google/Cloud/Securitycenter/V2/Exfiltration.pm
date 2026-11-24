package Google::Cloud::Securitycenter::V2::Exfiltration;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvZXhmaWx0cmF0aW9uLnByb3RvEh5n
b29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIi2AEKDEV4ZmlsdHJhdGlvbhJHCgdzb3Vy
Y2VzGAEgAygLMi0uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyLkV4ZmlsUmVzb3Vy
Y2VSB3NvdXJjZXMSRwoHdGFyZ2V0cxgCIAMoCzItLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNl
bnRlci52Mi5FeGZpbFJlc291cmNlUgd0YXJnZXRzEjYKF3RvdGFsX2V4ZmlsdHJhdGVkX2J5
dGVzGAMgASgDUhV0b3RhbEV4ZmlsdHJhdGVkQnl0ZXMiQwoNRXhmaWxSZXNvdXJjZRISCgRu
YW1lGAEgASgJUgRuYW1lEh4KCmNvbXBvbmVudHMYAiADKAlSCmNvbXBvbmVudHNC6wEKImNv
bS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjJCEUV4ZmlsdHJhdGlvblByb3RvUAFa
SmNsb3VkLmdvb2dsZS5jb20vZ28vc2VjdXJpdHljZW50ZXIvYXBpdjIvc2VjdXJpdHljZW50
ZXJwYjtzZWN1cml0eWNlbnRlcnBiqgIeR29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYy
ygIeR29vZ2xlXENsb3VkXFNlY3VyaXR5Q2VudGVyXFYy6gIhR29vZ2xlOjpDbG91ZDo6U2Vj
dXJpdHlDZW50ZXI6OlYySoARCgYSBA4AOAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQACcKCAoBCBIDEgA7CgkKAgglEgMSADsKCAoBCBIDEwBhCgkKAggL
EgMTAGEKCAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQAyCgkKAggIEgMVADIKCAoBCBID
FgA7CgkKAggBEgMWADsKCAoBCBIDFwA7CgkKAggpEgMXADsKCAoBCBIDGAA6CgkKAggtEgMY
ADoKgAIKAgQAEgQeACoBGvMBIEV4ZmlsdHJhdGlvbiByZXByZXNlbnRzIGEgZGF0YSBleGZp
bHRyYXRpb24gYXR0ZW1wdCBmcm9tIG9uZSBvciBtb3JlIHNvdXJjZXMKIHRvIG9uZSBvciBt
b3JlIHRhcmdldHMuIFRoZSBgc291cmNlc2AgYXR0cmlidXRlIGxpc3RzIHRoZSBzb3VyY2Vz
IG9mIHRoZQogZXhmaWx0cmF0ZWQgZGF0YS4gVGhlIGB0YXJnZXRzYCBhdHRyaWJ1dGUgbGlz
dHMgdGhlIGRlc3RpbmF0aW9ucyB0aGUgZGF0YSB3YXMKIGNvcGllZCB0by4KCgoKAwQAARID
HggUCsEBCgQEAAIAEgMiAiUaswEgSWYgdGhlcmUgYXJlIG11bHRpcGxlIHNvdXJjZXMsIHRo
ZW4gdGhlIGRhdGEgaXMgY29uc2lkZXJlZCAiam9pbmVkIiBiZXR3ZWVuCiB0aGVtLiBGb3Ig
aW5zdGFuY2UsIEJpZ1F1ZXJ5IGNhbiBqb2luIG11bHRpcGxlIHRhYmxlcywgYW5kIGVhY2gK
IHRhYmxlIHdvdWxkIGJlIGNvbnNpZGVyZWQgYSBzb3VyY2UuCgoMCgUEAAIABBIDIgIKCgwK
BQQAAgAGEgMiCxgKDAoFBAACAAESAyIZIAoMCgUEAAIAAxIDIiMkCnEKBAQAAgESAyYCJRpk
IElmIHRoZXJlIGFyZSBtdWx0aXBsZSB0YXJnZXRzLCBlYWNoIHRhcmdldCB3b3VsZCBnZXQg
YSBjb21wbGV0ZSBjb3B5IG9mIHRoZQogImpvaW5lZCIgc291cmNlIGRhdGEuCgoMCgUEAAIB
BBIDJgIKCgwKBQQAAgEGEgMmCxgKDAoFBAACAQESAyYZIAoMCgUEAAIBAxIDJiMkCkQKBAQA
AgISAykCJBo3IFRvdGFsIGV4ZmlsdHJhdGVkIGJ5dGVzIHByb2Nlc3NlZCBmb3IgdGhlIGVu
dGlyZSBqb2IuCgoMCgUEAAICBRIDKQIHCgwKBQQAAgIBEgMpCB8KDAoFBAACAgMSAykiIwpJ
CgIEARIELQA4ARo9IFJlc291cmNlIHdoZXJlIGRhdGEgd2FzIGV4ZmlsdHJhdGVkIGZyb20g
b3IgZXhmaWx0cmF0ZWQgdG8uCgoKCgMEAQESAy0IFQp8CgQEAQIAEgMwAhIabyBUaGUgcmVz
b3VyY2UncyBbZnVsbCByZXNvdXJjZQogbmFtZV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29t
L2FwaXMvZGVzaWduL3Jlc291cmNlX25hbWVzI2Z1bGxfcmVzb3VyY2VfbmFtZSkuCgoMCgUE
AQIABRIDMAIICgwKBQQBAgABEgMwCQ0KDAoFBAECAAMSAzAQEQq8AgoEBAECARIDNwIhGq4C
IFN1YmNvbXBvbmVudHMgb2YgdGhlIGFzc2V0IHRoYXQgd2FzIGV4ZmlsdHJhdGVkLCBsaWtl
IFVSSXMgdXNlZCBkdXJpbmcKIGV4ZmlsdHJhdGlvbiwgdGFibGUgbmFtZXMsIGRhdGFiYXNl
cywgYW5kIGZpbGVuYW1lcy4gRm9yIGV4YW1wbGUsIG11bHRpcGxlCiB0YWJsZXMgbWlnaHQg
aGF2ZSBiZWVuIGV4ZmlsdHJhdGVkIGZyb20gdGhlIHNhbWUgQ2xvdWQgU1FMIGluc3RhbmNl
LCBvcgogbXVsdGlwbGUgZmlsZXMgbWlnaHQgaGF2ZSBiZWVuIGV4ZmlsdHJhdGVkIGZyb20g
dGhlIHNhbWUgQ2xvdWQgU3RvcmFnZQogYnVja2V0LgoKDAoFBAECAQQSAzcCCgoMCgUEAQIB
BRIDNwsRCgwKBQQBAgEBEgM3EhwKDAoFBAECAQMSAzcfIGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::Exfiltration::Exfiltration ===
    # Fields for Exfiltration
    # Field: sources Type: 11 (.google.cloud.securitycenter.v2.ExfilResource)
    # Field: targets Type: 11 (.google.cloud.securitycenter.v2.ExfilResource)
    # Field: total_exfiltrated_bytes Type: 3 ()

# === Message: Google::Cloud::Securitycenter::V2::Exfiltration::ExfilResource ===
    # Fields for ExfilResource
    # Field: name Type: 9 ()
    # Field: components Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::Exfiltration - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/exfiltration.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::Exfiltration;

    my $msg = Google::Cloud::Securitycenter::V2::Exfiltration::Exfiltration->new({
        sources => $sources,
        targets => $targets,
        total_exfiltrated_bytes => $total_exfiltrated_bytes,
    });

    # Read or update a field
    my $val = $msg->sources();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::Exfiltration::Exfiltration->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/exfiltration.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::Exfiltration::Exfiltration

Exfiltration represents a data exfiltration attempt from one or more sources
to one or more targets. The `sources` attribute lists the sources of the
exfiltrated data. The `targets` attribute lists the destinations the data was
copied to.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sources() >> / C<< $msg->sources($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Exfiltration::ExfilResource>)

If there are multiple sources, then the data is considered "joined" between
them. For instance, BigQuery can join multiple tables, and each
table would be considered a source.

=item * C<< $msg->targets() >> / C<< $msg->targets($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Exfiltration::ExfilResource>)

If there are multiple targets, each target would get a complete copy of the
"joined" source data.

=item * C<< $msg->total_exfiltrated_bytes() >> / C<< $msg->total_exfiltrated_bytes($value) >>

Type: C<Int64>

Total exfiltrated bytes processed for the entire job.

=back

=head2 Google::Cloud::Securitycenter::V2::Exfiltration::ExfilResource

Resource where data was exfiltrated from or exfiltrated to.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource's [full resource
name](https://cloud.google.com/apis/design/resource_names#full_resource_name).

=item * C<< $msg->components() >> / C<< $msg->components($value) >>

Type: C<String>

Subcomponents of the asset that was exfiltrated, like URIs used during
exfiltration, table names, databases, and filenames. For example, multiple
tables might have been exfiltrated from the same Cloud SQL instance, or
multiple files might have been exfiltrated from the same Cloud Storage
bucket.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::Exfiltration::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
