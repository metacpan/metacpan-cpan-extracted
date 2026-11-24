package Google::Cloud::Apptopology::V1::Graph;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvYXBwdG9wb2xvZ3kvdjEvZ3JhcGgucHJvdG8SG2dvb2dsZS5jbG91
ZC5hcHB0b3BvbG9neS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxocZ29v
Z2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90byJ5CgVHcmFwaBI3CgVub2RlcxgBIAMoCzIhLmdv
b2dsZS5jbG91ZC5hcHB0b3BvbG9neS52MS5Ob2RlUgVub2RlcxI3CgVlZGdlcxgCIAMoCzIh
Lmdvb2dsZS5jbG91ZC5hcHB0b3BvbG9neS52MS5FZGdlUgVlZGdlcyIjCg1FbnRpdHlDb250
ZXh0EhIKBHR5cGUYASABKAlSBHR5cGUisQEKBE5vZGUSNwoKcHJvcGVydGllcxgDIAEoCzIX
Lmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSCnByb3BlcnRpZXMSEgoEbmFtZRgEIAEoCVIEbmFt
ZRIWCgZsYWJlbHMYBSADKAlSBmxhYmVscxJECgdjb250ZXh0GAYgASgLMiouZ29vZ2xlLmNs
b3VkLmFwcHRvcG9sb2d5LnYxLkVudGl0eUNvbnRleHRSB2NvbnRleHQi+wEKBEVkZ2USNwoK
cHJvcGVydGllcxgFIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSCnByb3BlcnRpZXMS
KAoQc291cmNlX25vZGVfbmFtZRgGIAEoCVIOc291cmNlTm9kZU5hbWUSMgoVZGVzdGluYXRp
b25fbm9kZV9uYW1lGAcgASgJUhNkZXN0aW5hdGlvbk5vZGVOYW1lEhYKBmxhYmVscxgIIAMo
CVIGbGFiZWxzEkQKB2NvbnRleHQYCSABKAsyKi5nb29nbGUuY2xvdWQuYXBwdG9wb2xvZ3ku
djEuRW50aXR5Q29udGV4dFIHY29udGV4dELPAQofY29tLmdvb2dsZS5jbG91ZC5hcHB0b3Bv
bG9neS52MUIKR3JhcGhQcm90b1ABWkFjbG91ZC5nb29nbGUuY29tL2dvL2FwcHRvcG9sb2d5
L2FwaXYxL2FwcHRvcG9sb2d5cGI7YXBwdG9wb2xvZ3lwYqoCG0dvb2dsZS5DbG91ZC5BcHBU
b3BvbG9neS5WMcoCG0dvb2dsZVxDbG91ZFxBcHBUb3BvbG9neVxWMeoCHkdvb2dsZTo6Q2xv
dWQ6OkFwcFRvcG9sb2d5OjpWMUrCHAoGEgQOAGYBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSACkKCQoCAwESAxMAJgoICgEIEgMVADgK
CQoCCCUSAxUAOAoICgEIEgMWAFgKCQoCCAsSAxYAWAoICgEIEgMXACIKCQoCCAoSAxcAIgoI
CgEIEgMYACsKCQoCCAgSAxgAKwoICgEIEgMZADgKCQoCCAESAxkAOAoICgEIEgMaADgKCQoC
CCkSAxoAOAoICgEIEgMbADcKCQoCCC0SAxsANwpHCgIEABIEHgAlARo7IFJlcHJlc2VudHMg
YSBncmFwaCBzdHJ1Y3R1cmUgY29tcG9zZWQgb2Ygbm9kZXMgYW5kIGVkZ2VzLgoKCgoDBAAB
EgMeCA0KQwoEBAACABIDIAIaGjYgQSBjb2xsZWN0aW9uIG9mIHVuaXF1ZSBub2RlcyB0aGF0
IG1ha2UgdXAgdGhlIGdyYXBoLgoKDAoFBAACAAQSAyACCgoMCgUEAAIABhIDIAsPCgwKBQQA
AgABEgMgEBUKDAoFBAACAAMSAyAYGQqmAQoEBAACARIDJAIaGpgBIENvbGxlY3Rpb24gb2Yg
dW5pcXVlIGVkZ2VzIGNvbm5lY3RpbmcgdGhlIGBub2Rlc2AgaW4gdGhlIGdyYXBoLiBCb3Ro
IHNvdXJjZQogYW5kIGRlc3RpbmF0aW9uIG5vZGVzIGZvciBlYWNoIGVkZ2VzIHdpbGwgYmUg
cHJlc2VudCBpbiB0aGUgYG5vZGVzYCBsaXN0LgoKDAoFBAACAQQSAyQCCgoMCgUEAAIBBhID
JAsPCgwKBQQAAgEBEgMkEBUKDAoFBAACAQMSAyQYGQpOCgIEARIEKAAtARpCIFJlcHJlc2Vu
dHMgdGhlIGNvbnRleHQgb2YgYW4gZW50aXR5IChub2RlIG9yIGVkZ2UpIGluIHRoZSBncmFw
aC4KCgoKAwQBARIDKAgVCtQBCgQEAQIAEgMsAhIaxgEgVGhlIHByaW1hcnksIG5hbWVzcGFj
ZWQgdHlwZSBkaWN0YXRpbmcgdGhlIG5vZGUgbmFtaW5nIGZvcm1hdCBhbmQgc3VwcG9ydGVk
CiBsYWJlbHMsIGFuZCBkZWZpbmVkIGluIHRoZSBgU2NoZW1hYCAoU2NoZW1hLm5vZGVfdHlw
ZXMvZWRnZV90eXBlcy5uYW1lKSwKIGUuZy4sIGBCYXNlL2NvbXB1dGUuZ29vZ2xlYXBpcy5j
b20vSW5zdGFuY2VgLgoKDAoFBAECAAUSAywCCAoMCgUEAQIAARIDLAkNCgwKBQQBAgADEgMs
EBEKNAoCBAISBDAATQEaKCBSZXByZXNlbnRzIGEgc2luZ2xlIG5vZGUgaW4gdGhlIGdyYXBo
LgoKCgoDBAIBEgMwCAwKlwEKBAQCAgASAzQCKBqJASBQcm9wZXJ0aWVzIGFzc29jaWF0ZWQg
d2l0aCB0aGUgbm9kZS4KIFJlZmVyIHRvIGh0dHBzOi8vYXBwdG9wb2xvZ3kuZ29vZ2xlYXBp
cy5jb20vdjEvR2V0U2NoZW1hIGZvciBhIGRldGFpbGVkCiBsaXN0IG9mIG5vZGUgcHJvcGVy
dGllcy4KCgwKBQQCAgAGEgM0AhgKDAoFBAICAAESAzQZIwoMCgUEAgIAAxIDNCYnCsEDCgQE
AgIBEgNDAhIaswMgVGhlIGdsb2JhbCB1bmlxdWUgbmFtZSBvZiB0aGUgbm9kZS4KIEZvciBz
dGFuZGFyZCBHb29nbGUgQ2xvdWQgUGxhdGZvcm0gcmVzb3VyY2VzLCB0aGlzIE1VU1QgYmUg
dGhlIGNhbm9uaWNhbAogRnVsbCBSZXNvdXJjZSBOYW1lLgoKIEV4YW1wbGVzOgoKIC0gdHlw
ZTogY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9JbnN0YW5jZQogICBuYW1lOgogICAiLy9jb21w
dXRlLmdvb2dsZWFwaXMuY29tL3Byb2plY3RzL215LXByb2plY3QtaWQvem9uZXMvdXMtY2Vu
dHJhbDEtYS9pbnN0YW5jZXMvbXktdm0tMSIKCiAtIHR5cGU6IGNvbnRhaW5lci5nb29nbGVh
cGlzLmNvbS9DbHVzdGVyCiAgIG5hbWU6CiAgICIvL2NvbnRhaW5lci5nb29nbGVhcGlzLmNv
bS9wcm9qZWN0cy9teS1wcm9qZWN0LWlkL2xvY2F0aW9ucy91cy1jZW50cmFsMS9jbHVzdGVy
cy9teS1jbHVzdGVyIgoKDAoFBAICAQUSA0MCCAoMCgUEAgIBARIDQwkNCgwKBQQCAgEDEgND
EBEK+AEKBAQCAgISA0kCHRrqASBMYWJlbHMgYXR0YWNoZWQgdG8gdGhlIG5vZGUuIENvbXBv
c2FibGUsIG5hbWVzcGFjZWQgYnVpbGRpbmcgYmxvY2tzIHRoYXQKIGRlZmluZSBjb3JlIGF0
dHJpYnV0ZXMgdGhyb3VnaCBhc3NvY2lhdGVkIHByb3BlcnRpZXMuIE11bHRpcGxlIGxhYmVs
cwogYWdncmVnYXRlIHRvIGZ1bGx5IHNwZWNpZnkgdGhlIGZ1bmN0aW9uYWwgdHJhaXRzIGFu
ZCBwcm9wZXJ0eSBzY2hlbWEgb2YgdGhlCiBub2RlIHR5cGUuCgoMCgUEAgICBBIDSQIKCgwK
BQQCAgIFEgNJCxEKDAoFBAICAgESA0kSGAoMCgUEAgICAxIDSRscCicKBAQCAgMSA0wCHBoa
IFRoZSBjb250ZXh0IG9mIHRoZSBub2RlLgoKDAoFBAICAwYSA0wCDwoMCgUEAgIDARIDTBAX
CgwKBQQCAgMDEgNMGhsKSQoCBAMSBFAAZgEaPSBSZXByZXNlbnRzIGEgc2luZ2xlIGVkZ2Ug
Y29ubmVjdGluZyB0d28gbm9kZXMgaW4gdGhlIGdyYXBoLgoKCgoDBAMBEgNQCAwKlwEKBAQD
AgASA1QCKBqJASBQcm9wZXJ0aWVzIGFzc29jaWF0ZWQgd2l0aCB0aGUgZWRnZS4KIFJlZmVy
IHRvIGh0dHBzOi8vYXBwdG9wb2xvZ3kuZ29vZ2xlYXBpcy5jb20vdjEvR2V0U2NoZW1hIGZv
ciBhIGRldGFpbGVkCiBsaXN0IG9mIGVkZ2UgcHJvcGVydGllcy4KCgwKBQQDAgAGEgNUAhgK
DAoFBAMCAAESA1QZIwoMCgUEAwIAAxIDVCYnCmAKBAQDAgESA1gCHhpTIFRoZSBuYW1lIG9m
IHRoZSBzb3VyY2Ugbm9kZSBmb3IgdGhpcyBlZGdlLiBUaGlzIGlzIHRoZSBgbmFtZWAgZmll
bGQgaW4gdGhlCiBOb2RlLgoKDAoFBAMCAQUSA1gCCAoMCgUEAwIBARIDWAkZCgwKBQQDAgED
EgNYHB0KZQoEBAMCAhIDXAIjGlggVGhlIG5hbWUgb2YgdGhlIGRlc3RpbmF0aW9uIG5vZGUg
Zm9yIHRoaXMgZWRnZS4gVGhpcyBpcyB0aGUgYG5hbWVgIGZpZWxkIGluCiB0aGUgTm9kZS4K
CgwKBQQDAgIFEgNcAggKDAoFBAMCAgESA1wJHgoMCgUEAwICAxIDXCEiCvgBCgQEAwIDEgNi
Ah0a6gEgTGFiZWxzIGF0dGFjaGVkIHRvIHRoZSBlZGdlLiBDb21wb3NhYmxlLCBuYW1lc3Bh
Y2VkIGJ1aWxkaW5nIGJsb2NrcyB0aGF0CiBkZWZpbmUgY29yZSBhdHRyaWJ1dGVzIHRocm91
Z2ggYXNzb2NpYXRlZCBwcm9wZXJ0aWVzLiBNdWx0aXBsZSBsYWJlbHMKIGFnZ3JlZ2F0ZSB0
byBmdWxseSBzcGVjaWZ5IHRoZSBmdW5jdGlvbmFsIHRyYWl0cyBhbmQgcHJvcGVydHkgc2No
ZW1hIG9mIHRoZQogZWRnZSB0eXBlLgoKDAoFBAMCAwQSA2ICCgoMCgUEAwIDBRIDYgsRCgwK
BQQDAgMBEgNiEhgKDAoFBAMCAwMSA2IbHAonCgQEAwIEEgNlAhwaGiBUaGUgY29udGV4dCBv
ZiB0aGUgZWRnZS4KCgwKBQQDAgQGEgNlAg8KDAoFBAMCBAESA2UQFwoMCgUEAwIEAxIDZRob
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apptopology::V1::Graph::Graph ===
    # Fields for Graph
    # Field: nodes Type: 11 (.google.cloud.apptopology.v1.Node)
    # Field: edges Type: 11 (.google.cloud.apptopology.v1.Edge)

# === Message: Google::Cloud::Apptopology::V1::Graph::EntityContext ===
    # Fields for EntityContext
    # Field: type Type: 9 ()

# === Message: Google::Cloud::Apptopology::V1::Graph::Node ===
    # Fields for Node
    # Field: properties Type: 11 (.google.protobuf.Struct)
    # Field: name Type: 9 ()
    # Field: labels Type: 9 ()
    # Field: context Type: 11 (.google.cloud.apptopology.v1.EntityContext)

# === Message: Google::Cloud::Apptopology::V1::Graph::Edge ===
    # Fields for Edge
    # Field: properties Type: 11 (.google.protobuf.Struct)
    # Field: source_node_name Type: 9 ()
    # Field: destination_node_name Type: 9 ()
    # Field: labels Type: 9 ()
    # Field: context Type: 11 (.google.cloud.apptopology.v1.EntityContext)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apptopology::V1::Graph - Compiled Protocol Buffers messages for google/cloud/apptopology/v1/graph.proto

=head1 SYNOPSIS

    use Google::Cloud::Apptopology::V1::Graph;

    my $msg = Google::Cloud::Apptopology::V1::Graph::Graph->new({
        nodes => $nodes,
        edges => $edges,
    });

    # Read or update a field
    my $val = $msg->nodes();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apptopology::V1::Graph::Graph->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apptopology/v1/graph.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apptopology::V1::Graph::Graph

Represents a graph structure composed of nodes and edges.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->nodes() >> / C<< $msg->nodes($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Graph::Node>)

A collection of unique nodes that make up the graph.

=item * C<< $msg->edges() >> / C<< $msg->edges($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Graph::Edge>)

Collection of unique edges connecting the `nodes` in the graph. Both source
and destination nodes for each edges will be present in the `nodes` list.

=back

=head2 Google::Cloud::Apptopology::V1::Graph::EntityContext

Represents the context of an entity (node or edge) in the graph.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

The primary, namespaced type dictating the node naming format and supported
labels, and defined in the `Schema` (Schema.node_types/edge_types.name),
e.g., `Base/compute.googleapis.com/Instance`.

=back

=head2 Google::Cloud::Apptopology::V1::Graph::Node

Represents a single node in the graph.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Properties associated with the node.
Refer to https://apptopology.googleapis.com/v1/GetSchema for a detailed
list of node properties.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The global unique name of the node.
For standard Google Cloud Platform resources, this MUST be the canonical
Full Resource Name.

Examples:

- type: compute.googleapis.com/Instance
  name:
  "//compute.googleapis.com/projects/my-project-id/zones/us-central1-a/instances/my-vm-1"

- type: container.googleapis.com/Cluster
  name:
  "//container.googleapis.com/projects/my-project-id/locations/us-central1/clusters/my-cluster"

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<String>

Labels attached to the node. Composable, namespaced building blocks that
define core attributes through associated properties. Multiple labels
aggregate to fully specify the functional traits and property schema of the
node type.

=item * C<< $msg->context() >> / C<< $msg->context($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Graph::EntityContext>)

The context of the node.

=back

=head2 Google::Cloud::Apptopology::V1::Graph::Edge

Represents a single edge connecting two nodes in the graph.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Properties associated with the edge.
Refer to https://apptopology.googleapis.com/v1/GetSchema for a detailed
list of edge properties.

=item * C<< $msg->source_node_name() >> / C<< $msg->source_node_name($value) >>

Type: C<String>

The name of the source node for this edge. This is the `name` field in the
Node.

=item * C<< $msg->destination_node_name() >> / C<< $msg->destination_node_name($value) >>

Type: C<String>

The name of the destination node for this edge. This is the `name` field in
the Node.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<String>

Labels attached to the edge. Composable, namespaced building blocks that
define core attributes through associated properties. Multiple labels
aggregate to fully specify the functional traits and property schema of the
edge type.

=item * C<< $msg->context() >> / C<< $msg->context($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Graph::EntityContext>)

The context of the edge.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apptopology::V1::Graph::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
